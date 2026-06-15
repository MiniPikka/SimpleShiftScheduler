import { ShiftType, DEFAULT_SHIFT_CYCLE, DEFAULT_REFERENCE_DATE } from '../constants/ShiftConstants'
import { CalendarDayInfo } from '../models/ShiftModels'
import { getShiftTypeForDate, formatDate } from './ShiftCalculator'

export function generateMonthCalendarDays(
  year: number,
  month: number,
  teamId: number = 1,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): CalendarDayInfo[] {
  const today = new Date()
  const todayStr = formatDate(today)
  const firstDay = new Date(year, month - 1, 1)
  const startWeekday = firstDay.getDay()
  const daysInMonth = new Date(year, month, 0).getDate()
  const daysInPrevMonth = new Date(year, month - 1, 0).getDate()

  const result: CalendarDayInfo[] = []

  for (let i = startWeekday - 1; i >= 0; i--) {
    const day = daysInPrevMonth - i
    const d = new Date(year, month - 2, day)
    const ds = formatDate(d)
    result.push({
      date: ds,
      day: day,
      shiftType: getShiftTypeForDate(d, teamId, customCycle, referenceDateStr),
      isCurrentMonth: false,
      isToday: ds === todayStr
    })
  }

  for (let d = 1; d <= daysInMonth; d++) {
    const date = new Date(year, month - 1, d)
    const ds = formatDate(date)
    result.push({
      date: ds,
      day: d,
      shiftType: getShiftTypeForDate(date, teamId, customCycle, referenceDateStr),
      isCurrentMonth: true,
      isToday: ds === todayStr
    })
  }

  const remaining = 42 - result.length
  for (let d = 1; d <= remaining; d++) {
    const date = new Date(year, month, d)
    const ds = formatDate(date)
    result.push({
      date: ds,
      day: d,
      shiftType: getShiftTypeForDate(date, teamId, customCycle, referenceDateStr),
      isCurrentMonth: false,
      isToday: ds === todayStr
    })
  }

  return result
}
