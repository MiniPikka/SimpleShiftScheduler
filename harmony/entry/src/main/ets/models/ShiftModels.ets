import { ShiftType } from '../constants/ShiftConstants'

export interface ShiftInfo {
  date: string
  dayOfCycle: number
  shiftType: ShiftType
}

export interface CalendarDayInfo {
  date: string
  day: number
  shiftType: ShiftType
  isCurrentMonth: boolean
  isToday: boolean
}

export interface MonthlyStats {
  counts: Map<ShiftType, number>
  totalWorkDays: number
  totalDays: number
}

export interface AlarmTime {
  hour: number
  minute: number
}

export interface AlarmSettings {
  alarms: Map<ShiftType, AlarmTime | null>
}

export interface SalaryConfig {
  premiums: Map<ShiftType, number>
}

export interface SalaryBreakdown {
  year: number
  month: number
  counts: Map<ShiftType, number>
  total: number
}

export interface LeaveStrategy {
  leaveDays: number
  totalBreakDays: number
  leaveDates: string[]
  breakStart: string
  breakEnd: string
  holidayOverlap: number
  weekendOverlap: number
  overlappingHolidayNames: string[]
  efficiency: number
  score: number
}

export interface CommonRestResult {
  teamAName: string
  teamBName: string
  nextCommonRestDate: string
  daysUntilNext: number
  commonRestDates: string[]
  totalCount: number
  countIn30Days: number
  countIn60Days: number
}

export interface HomeState {
  shiftType: ShiftType
  dayOfCycle: number
  daysUntilRest: number
  consecutiveWorkDays: number
  monthlyWorkDays: number
  monthlyTotalDays: number
  alarmTimeStr: string
  teamName: string
  dateStr: string
  greeting: string
  tomorrowShiftType: ShiftType
  predecessorTeamId: number
  predecessorShiftType: ShiftType
  successorTeamId: number
  successorShiftType: ShiftType
}
