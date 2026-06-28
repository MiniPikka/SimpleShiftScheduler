import { ShiftType, DEFAULT_SHIFT_CYCLE, DEFAULT_REFERENCE_DATE } from '../constants/ShiftConstants'
import { LeaveStrategy } from '../models/ShiftModels'
import { getShiftTypeForDate, isWorkDay, formatDate, parseDate, daysBetween } from './ShiftCalculator'
import { HolidayData } from './HolidayData'

interface DayStatus {
  date: string
  isShiftRest: boolean
  isHoliday: boolean
  isWeekend: boolean
  isAdjustedWorkDay: boolean
  isOff: boolean
  holidayName: string
}

function getDayStatus(date: Date, shiftType: ShiftType): DayStatus {
  const ds = formatDate(date)
  const dayOfWeek = date.getDay()
  const holiday = HolidayData.getHolidayInfo(ds)
  const isWeekend = dayOfWeek === 0 || dayOfWeek === 6
  const isHoliday = holiday !== null && holiday.isHoliday
  const isAdjustedWorkDay = holiday !== null && !holiday.isHoliday
  const isShiftRest = !isWorkDay(shiftType)
  const isOff = isShiftRest || (isHoliday && !isAdjustedWorkDay) || (isWeekend && !isAdjustedWorkDay)

  return {
    date: ds,
    isShiftRest,
    isHoliday,
    isWeekend,
    isAdjustedWorkDay,
    isOff,
    holidayName: holiday !== null ? holiday.name : ''
  }
}

export function findBestLeavePlans(
  teamId: number = 1,
  maxLeaveDays: number = 5,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): LeaveStrategy[] {
  if (maxLeaveDays < 1) return []

  const today = new Date()
  const endOfYear = new Date(today.getFullYear(), 11, 31)
  const totalDays = daysBetween(today, endOfYear) + 1

  if (totalDays < 1) return []

  const statuses: DayStatus[] = []
  for (let i = 0; i < totalDays; i++) {
    const d = new Date(today)
    d.setDate(d.getDate() + i)
    const st = getShiftTypeForDate(d, teamId, customCycle, referenceDateStr)
    statuses.push(getDayStatus(d, st))
  }
  const n = statuses.length

  const restBefore = new Array<number>(n).fill(0)
  const restAfter = new Array<number>(n).fill(0)
  for (let i = 1; i < n; i++) {
    restBefore[i] = statuses[i - 1].isOff ? restBefore[i - 1] + 1 : 0
  }
  for (let i = n - 2; i >= 0; i--) {
    restAfter[i] = statuses[i + 1].isOff ? restAfter[i + 1] + 1 : 0
  }

  const strategies: LeaveStrategy[] = []
  const minLeaveDays = maxLeaveDays === 1 ? 1 : 2

  for (let leaveDays = minLeaveDays; leaveDays <= maxLeaveDays; leaveDays++) {
    for (let startIdx = 0; startIdx <= n - leaveDays; startIdx++) {
      let hasShiftRest = false
      for (let j = 0; j < leaveDays; j++) {
        if (statuses[startIdx + j].isShiftRest) { hasShiftRest = true; break }
      }
      if (hasShiftRest) continue

      const leftRest = restBefore[startIdx]
      const rightRest = restAfter[startIdx + leaveDays - 1]
      const totalBreak = leftRest + leaveDays + rightRest
      if (totalBreak <= leaveDays) continue

      const gapStart = startIdx - leftRest
      const gapEnd = startIdx + leaveDays - 1 + rightRest
      const breakStart = statuses[gapStart].date
      const breakEnd = statuses[gapEnd].date

      let holidayOverlap = 0
      let weekendOverlap = 0
      const overlappingNames: string[] = []
      for (let idx = gapStart; idx <= gapEnd; idx++) {
        const s = statuses[idx]
        if (s.isHoliday) {
          holidayOverlap++
          if (s.holidayName && overlappingNames.indexOf(s.holidayName) < 0) {
            overlappingNames.push(s.holidayName)
          }
        }
        if (s.isWeekend && !s.isAdjustedWorkDay) weekendOverlap++
      }

      const leaveDates: string[] = []
      for (let j = 0; j < leaveDays; j++) {
        leaveDates.push(statuses[startIdx + j].date)
      }
      const efficiency = totalBreak / leaveDays

      strategies.push({
        leaveDays,
        totalBreakDays: totalBreak,
        leaveDates,
        breakStart,
        breakEnd,
        holidayOverlap,
        weekendOverlap,
        overlappingHolidayNames: overlappingNames,
        efficiency,
        score: 0
      })
    }
  }

  const deduped = new Map<string, LeaveStrategy>()
  for (const s of strategies) {
    const key = `${s.breakStart}_${s.breakEnd}`
    const existing = deduped.get(key)
    if (!existing || s.leaveDays < existing.leaveDays) {
      deduped.set(key, s)
    }
  }
  if (deduped.size === 0) return []

  const dedupedList = Array.from(deduped.values())
  const maxEfficiency = dedupedList.reduce((m, s) => Math.max(m, s.efficiency), 0)
  const maxBreak = dedupedList.reduce((m, s) => Math.max(m, s.totalBreakDays), 0)
  const maxFamilyBonus = Math.max(1, dedupedList.reduce((m, s) => Math.max(m, s.holidayOverlap * 2 + s.weekendOverlap), 0))

  for (const s of dedupedList) {
    const effScore = maxEfficiency > 0 ? s.efficiency / maxEfficiency : 0
    const lenScore = maxBreak > 0 ? s.totalBreakDays / maxBreak : 0
    const familyBonus = s.holidayOverlap * 2 + s.weekendOverlap
    const famScore = familyBonus / maxFamilyBonus
    s.score = 0.50 * effScore + 0.25 * lenScore + 0.25 * famScore
  }

  dedupedList.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score
    return a.breakStart < b.breakStart ? -1 : a.breakStart > b.breakStart ? 1 : 0
  })
  return dedupedList
}
