import { ShiftType, DEFAULT_SHIFT_CYCLE, DEFAULT_REFERENCE_DATE } from '../constants/ShiftConstants'
import { MonthlyStats } from '../models/ShiftModels'
import { getShiftTypeForDate, isWorkDay } from './ShiftCalculator'

export function countShiftTypeInMonth(
  year: number,
  month: number,
  shiftType: ShiftType,
  teamId: number = 1,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): number {
  const daysInMonth = new Date(year, month, 0).getDate()
  let count = 0
  for (let d = 1; d <= daysInMonth; d++) {
    const date = new Date(year, month - 1, d)
    if (getShiftTypeForDate(date, teamId, customCycle, referenceDateStr) === shiftType) {
      count++
    }
  }
  return count
}

export function countAllShiftTypesInMonth(
  year: number,
  month: number,
  teamId: number = 1,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): Map<ShiftType, number> {
  const counts = new Map<ShiftType, number>()
  counts.set(ShiftType.MORNING, 0)
  counts.set(ShiftType.AFTERNOON, 0)
  counts.set(ShiftType.REST, 0)
  counts.set(ShiftType.NIGHT, 0)
  counts.set(ShiftType.STUDY, 0)

  const daysInMonth = new Date(year, month, 0).getDate()
  for (let d = 1; d <= daysInMonth; d++) {
    const date = new Date(year, month - 1, d)
    const st = getShiftTypeForDate(date, teamId, customCycle, referenceDateStr)
    counts.set(st, (counts.get(st) || 0) + 1)
  }
  return counts
}

export function countWorkDaysInMonth(
  year: number,
  month: number,
  teamId: number = 1,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): number {
  const counts = countAllShiftTypesInMonth(year, month, teamId, customCycle, referenceDateStr)
  return (counts.get(ShiftType.MORNING) || 0) +
    (counts.get(ShiftType.AFTERNOON) || 0) +
    (counts.get(ShiftType.NIGHT) || 0)
}

export function getMonthlyStats(
  year: number,
  month: number,
  teamId: number = 1,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): MonthlyStats {
  const counts = countAllShiftTypesInMonth(year, month, teamId, customCycle, referenceDateStr)
  const daysInMonth = new Date(year, month, 0).getDate()
  const workDays = (counts.get(ShiftType.MORNING) || 0) +
    (counts.get(ShiftType.AFTERNOON) || 0) +
    (counts.get(ShiftType.NIGHT) || 0)
  return { counts, totalWorkDays: workDays, totalDays: daysInMonth }
}

export function consecutiveWorkDays(
  today: Date,
  teamId: number = 1,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): number {
  let count = 0
  const d = new Date(today)
  for (let i = 0; i < 42; i++) {
    const st = getShiftTypeForDate(d, teamId, customCycle, referenceDateStr)
    if (isWorkDay(st)) {
      count++
      d.setDate(d.getDate() - 1)
    } else {
      break
    }
  }
  return count
}

export function daysUntilNextRest(
  today: Date,
  teamId: number = 1,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): number {
  const d = new Date(today)
  d.setDate(d.getDate() + 1)
  for (let i = 0; i < 10000; i++) {
    const st = getShiftTypeForDate(d, teamId, customCycle, referenceDateStr)
    if (!isWorkDay(st)) {
      return i
    }
    d.setDate(d.getDate() + 1)
  }
  return -1
}
