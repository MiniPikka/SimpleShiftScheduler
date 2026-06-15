import { ShiftType, DEFAULT_SHIFT_CYCLE, DEFAULT_REFERENCE_DATE } from '../constants/ShiftConstants'
import { LeaveStrategy } from '../models/ShiftModels'
import { getShiftTypeForDate, isWorkDay, formatDate, parseDate, daysBetween } from './ShiftCalculator'
import { HolidayData } from './HolidayData'

interface DayStatus {
  date: string
  isRest: boolean
  isHoliday: boolean
  isWeekend: boolean
  isAdjustedWorkDay: boolean
  holidayName: string
}

function getDayStatus(date: Date): DayStatus {
  const ds = formatDate(date)
  const dayOfWeek = date.getDay()
  const holiday = HolidayData.getHolidayInfo(ds)
  const isWeekend = dayOfWeek === 0 || dayOfWeek === 6
  const isHoliday = holiday !== null && holiday.isHoliday
  const isAdjustedWorkDay = holiday !== null && !holiday.isHoliday

  let isNaturalRest = false
  if (isHoliday) {
    isNaturalRest = true
  } else if (isWeekend && !isAdjustedWorkDay) {
    isNaturalRest = true
  }

  return {
    date: ds,
    isRest: isNaturalRest,
    isHoliday: isHoliday,
    isWeekend: isWeekend,
    isAdjustedWorkDay: isAdjustedWorkDay,
    holidayName: holiday !== null ? holiday.name : ''
  }
}

export function findBestLeavePlans(
  teamId: number = 1,
  maxLeaveDays: number = 5,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): LeaveStrategy[] {
  const today = new Date()
  const endOfYear = new Date(today.getFullYear(), 11, 31)
  const totalDays = daysBetween(today, endOfYear)

  if (totalDays <= 0) return []

  const dayStatuses: DayStatus[] = []
  const shiftTypes: ShiftType[] = []
  for (let i = 0; i <= totalDays; i++) {
    const d = new Date(today)
    d.setDate(d.getDate() + i)
    dayStatuses.push(getDayStatus(d))
    shiftTypes.push(getShiftTypeForDate(d, teamId, customCycle, referenceDateStr))
  }

  const strategies: LeaveStrategy[] = []

  for (let startIdx = 0; startIdx < totalDays; startIdx++) {
    const todayShift = shiftTypes[startIdx]
    if (!isWorkDay(todayShift)) continue

    for (let leaveLen = 1; leaveLen <= maxLeaveDays && startIdx + leaveLen <= totalDays; leaveLen++) {
      let allWorkDays = true
      const leaveDates: string[] = []

      for (let j = 0; j < leaveLen; j++) {
        const idx = startIdx + j
        if (idx >= dayStatuses.length) { allWorkDays = false; break }
        const shift = shiftTypes[idx]
        const status = dayStatuses[idx]

        if (!isWorkDay(shift) || status.isHoliday || status.isAdjustedWorkDay) {
          allWorkDays = false
          break
        }
        leaveDates.push(status.date)
      }
      if (!allWorkDays) continue

      let restBefore = 0
      for (let j = startIdx - 1; j >= 0; j--) {
        if (!isWorkDay(shiftTypes[j]) || dayStatuses[j].isHoliday) {
          restBefore++
        } else {
          break
        }
      }

      let restAfter = 0
      for (let j = startIdx + leaveLen; j < dayStatuses.length; j++) {
        if (!isWorkDay(shiftTypes[j]) || dayStatuses[j].isHoliday) {
          restAfter++
        } else {
          break
        }
      }

      const totalBreak = restBefore + leaveLen + restAfter
      if (totalBreak < 3) continue

      let holidayOverlap = 0
      let weekendOverlap = 0
      const overlappingNames: string[] = []

      const breakStartIdx = startIdx - restBefore
      const breakEndIdx = startIdx + leaveLen + restAfter - 1
      for (let j = breakStartIdx; j <= breakEndIdx && j < dayStatuses.length; j++) {
        if (j < 0) continue
        const st = dayStatuses[j]
        if (st.isHoliday) {
          holidayOverlap++
          if (st.holidayName && overlappingNames.indexOf(st.holidayName) < 0) {
            overlappingNames.push(st.holidayName)
          }
        }
        if (st.isWeekend) weekendOverlap++
      }

      const efficiency = totalBreak / leaveLen
      const lengthScore = Math.min(totalBreak / 10, 1)
      const familyScore = Math.min((holidayOverlap + weekendOverlap) / 5, 1)
      const score = efficiency * 0.5 + lengthScore * 0.25 + familyScore * 0.25

      strategies.push({
        leaveDays: leaveLen,
        totalBreakDays: totalBreak,
        leaveDates: leaveDates,
        breakStart: dayStatuses[Math.max(0, breakStartIdx)].date,
        breakEnd: dayStatuses[Math.min(breakEndIdx, dayStatuses.length - 1)].date,
        holidayOverlap: holidayOverlap,
        weekendOverlap: weekendOverlap,
        overlappingHolidayNames: overlappingNames,
        efficiency: Math.round(efficiency * 10) / 10,
        score: Math.round(score * 100) / 100
      })
    }
  }

  const deduped = new Map<string, LeaveStrategy>()
  for (const s of strategies) {
    const key = `${s.breakStart}_${s.breakEnd}`
    const existing = deduped.get(key)
    if (!existing || s.leaveDays < existing.leaveDays || (s.leaveDays === existing.leaveDays && s.score > existing.score)) {
      deduped.set(key, s)
    }
  }

  const result = Array.from(deduped.values())
  result.sort((a, b) => b.score - a.score)
  return result.slice(0, 10)
}
