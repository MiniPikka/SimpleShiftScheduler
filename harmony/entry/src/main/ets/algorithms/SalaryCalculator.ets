import { ShiftType, DEFAULT_SHIFT_CYCLE, DEFAULT_REFERENCE_DATE } from '../constants/ShiftConstants'
import { SalaryConfig, SalaryBreakdown } from '../models/ShiftModels'
import { countAllShiftTypesInMonth } from './ShiftMetrics'

export function defaultSalaryConfig(): SalaryConfig {
  const premiums = new Map<ShiftType, number>()
  premiums.set(ShiftType.MORNING, 0)
  premiums.set(ShiftType.AFTERNOON, 0)
  premiums.set(ShiftType.NIGHT, 0)
  premiums.set(ShiftType.STUDY, 0)
  return { premiums }
}

export function calculateSalaryBreakdown(
  year: number,
  month: number,
  config: SalaryConfig,
  teamId: number = 1,
  customCycle: ShiftType[] = DEFAULT_SHIFT_CYCLE,
  referenceDateStr: string = DEFAULT_REFERENCE_DATE
): SalaryBreakdown {
  const counts = countAllShiftTypesInMonth(year, month, teamId, customCycle, referenceDateStr)
  let total = 0
  counts.forEach((count, type) => {
    const premium = config.premiums.get(type) || 0
    total += count * premium
  })
  return {
    year,
    month,
    counts,
    total: Math.round(total * 100) / 100
  }
}

export function simulateExtraShifts(
  currentTotal: number,
  extraDays: number,
  shiftType: ShiftType,
  config: SalaryConfig
): number {
  const premium = config.premiums.get(shiftType) || 0
  return Math.round(extraDays * premium * 100) / 100
}
