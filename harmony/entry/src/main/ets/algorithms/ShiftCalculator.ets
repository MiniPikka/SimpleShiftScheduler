import { ShiftType, DEFAULT_SHIFT_CYCLE, DEFAULT_REFERENCE_DATE, TOTAL_TEAMS } from '../constants/ShiftConstants'
import { ShiftInfo, ShiftHandoverResult } from '../models/ShiftModels'

export function parseDate(dateStr: string): Date {
  const parts = dateStr.split('-')
  return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
}

export function formatDate(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

export function daysBetween(a: Date, b: Date): number {
  const msPerDay = 86400000
  const utcA = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate())
  const utcB = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate())
  return Math.floor((utcB - utcA) / msPerDay)
}

export function teamPhaseStep(cycleLength: number): number {
  return Math.floor(cycleLength / TOTAL_TEAMS)
}

export function teamPhaseOffset(teamId: number, cycleLength: number): number {
  return (teamId - 1) * teamPhaseStep(cycleLength)
}

export function getShiftTypeForDate(
  date: Date,
  teamId: number = 1,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): ShiftType {
  const refDate = parseDate(referenceDateStr)
  const offsetDays = daysBetween(refDate, date)
  const cycleLength = customCycle.length
  const phase = teamPhaseOffset(teamId, cycleLength)
  const idx = ((offsetDays + phase) % cycleLength + cycleLength) % cycleLength
  return customCycle[idx]
}

export function getShiftInfo(
  date: Date,
  teamId: number = 1,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): ShiftInfo {
  const refDate = parseDate(referenceDateStr)
  const offsetDays = daysBetween(refDate, date)
  const cycleLength = customCycle.length
  const phase = teamPhaseOffset(teamId, cycleLength)
  const idx = ((offsetDays + phase) % cycleLength + cycleLength) % cycleLength
  const dayOfCycle = idx + 1
  return {
    date: formatDate(date),
    dayOfCycle: dayOfCycle,
    shiftType: customCycle[idx]
  }
}

export function isWorkDay(shiftType: ShiftType): boolean {
  return shiftType === ShiftType.MORNING || shiftType === ShiftType.AFTERNOON || shiftType === ShiftType.NIGHT
}

export function isRestDay(shiftType: ShiftType): boolean {
  return shiftType === ShiftType.REST || shiftType === ShiftType.STUDY
}

/// The team that follows yours in the circular rotation order.
///
/// In a 6-team rotation, the successor of team N is team N+1 (with wraparound):
/// Team 1 → Team 2, Team 2 → Team 3, ..., Team 6 → Team 1.
///
/// Note: this reflects the circular team numbering, not a guarantee about
/// shift status. Whether the successor is working or resting on a given day
/// depends on the cycle position and is not always opposite.
export function successorTeamId(teamId: number): number {
  return (teamId % TOTAL_TEAMS) + 1
}

/// The team that yours follows in the circular rotation order.
///
/// The predecessor of team N is the team whose shift your team takes over.
/// In a 6-team rotation, the predecessor of team N is team N-1 (with wraparound):
/// Team 1 ← Team 6, Team 2 ← Team 1, ..., Team 6 ← Team 5.
export function predecessorTeamId(teamId: number): number {
  return (teamId + TOTAL_TEAMS - 2) % TOTAL_TEAMS + 1
}

/// Find which team you take over from and which team takes over from you,
/// based on shift types (夜 → 早 → 中 → 夜), NOT team numbering.
///
/// 跨天约定（与夜班提醒一致）：班次按结束日标记。夜班（前一晚 ~22:00 上岗、
/// 当天早上 8 点下班）的 中→夜 交接发生在前一个日历日的晚上：
/// - 夜班的前序（中班）查 date - 1
/// - 中班的后继（夜班）查 date + 1
/// - 早班两次交接都在同一天内，不受影响
///
/// Returns ShiftHandoverResult or null if you're not working.
export function shiftHandover(
  date: Date,
  teamId: number,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): ShiftHandoverResult | null {
  const myShift = getShiftTypeForDate(date, teamId, customCycle, referenceDateStr)
  if (isRestDay(myShift)) return null

  // 交接顺序：夜 → 早 → 中 → 夜
  let predShift: ShiftType, succShift: ShiftType
  if (myShift === ShiftType.MORNING) { predShift = ShiftType.NIGHT; succShift = ShiftType.AFTERNOON }
  else if (myShift === ShiftType.AFTERNOON) { predShift = ShiftType.MORNING; succShift = ShiftType.NIGHT }
  else { predShift = ShiftType.AFTERNOON; succShift = ShiftType.MORNING } // NIGHT

  // 跨天修正：中→夜 交接发生在我（或后继）上岗的前一晚
  const msPerDay = 86400000
  const predDate = myShift === ShiftType.NIGHT ? new Date(date.getTime() - msPerDay) : date
  const succDate = succShift === ShiftType.NIGHT ? new Date(date.getTime() + msPerDay) : date

  let predTeam = 0, succTeam = 0
  for (let t = 1; t <= TOTAL_TEAMS; t++) {
    if (t === teamId) continue
    if (predTeam === 0 &&
        getShiftTypeForDate(predDate, t, customCycle, referenceDateStr) === predShift) {
      predTeam = t
    }
    if (succTeam === 0 &&
        getShiftTypeForDate(succDate, t, customCycle, referenceDateStr) === succShift) {
      succTeam = t
    }
    if (predTeam > 0 && succTeam > 0) break
  }

  if (predTeam > 0 && succTeam > 0) {
    const result: ShiftHandoverResult = {
      predTeam: predTeam, predShift: predShift, succTeam: succTeam, succShift: succShift
    }
    return result
  }
  return null
}
