import { ShiftType, DEFAULT_SHIFT_CYCLE, DEFAULT_REFERENCE_DATE, TEAM_NAMES } from '../constants/ShiftConstants'
import { CommonRestResult } from '../models/ShiftModels'
import { getShiftTypeForDate, isWorkDay, formatDate, daysBetween, parseDate } from './ShiftCalculator'

export function findCommonRestDays(
  teamAId: number,
  teamBId: number,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): CommonRestResult {
  const today = new Date()
  const endOfYear = new Date(today.getFullYear(), 11, 31)
  const totalDays = daysBetween(today, endOfYear)

  const commonRestDates: string[] = []
  let countIn30 = 0
  let countIn60 = 0
  let nextDate = ''
  let daysUntilNext = -1

  for (let i = 0; i <= totalDays; i++) {
    const d = new Date(today)
    d.setDate(d.getDate() + i)
    const shiftA = getShiftTypeForDate(d, teamAId, customCycle, referenceDateStr)
    const shiftB = getShiftTypeForDate(d, teamBId, customCycle, referenceDateStr)
    const isRestA = !isWorkDay(shiftA)
    const isRestB = !isWorkDay(shiftB)

    if (isRestA && isRestB) {
      const ds = formatDate(d)
      commonRestDates.push(ds)
      if (i <= 30) countIn30++
      if (i <= 60) countIn60++
      if (nextDate === '' && i > 0) {
        nextDate = ds
        daysUntilNext = i
      }
    }
  }

  if (nextDate === '') {
    nextDate = formatDate(today)
    daysUntilNext = 0
  }

  return {
    teamAName: TEAM_NAMES[teamAId - 1],
    teamBName: TEAM_NAMES[teamBId - 1],
    nextCommonRestDate: nextDate,
    daysUntilNext: daysUntilNext,
    commonRestDates: commonRestDates,
    totalCount: commonRestDates.length,
    countIn30Days: countIn30,
    countIn60Days: countIn60
  }
}
