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

/**
 * 交接班查询结果 — 班组及交接时刻对方所在的班次类型。
 * 班次类型必须取交接时刻的班次，而非查询日当天的班次：
 * 例如 7-19 夜班（7-18 晚 22:00 上岗）的前序班组二值在 7-19 当天是休班，
 * 但交接时他在上 7-18 的中班。
 */
export interface ShiftHandoverResult {
  predTeam: number
  predShift: ShiftType
  succTeam: number
  succShift: ShiftType
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
