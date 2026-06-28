import { describe, it, expect } from '@ohos/hypium'
import { getShiftInfo, getShiftTypeForDate, shiftHandover, isWorkDay, isRestDay,
  parseDate, formatDate, daysBetween, teamPhaseOffset } from '../main/ets/algorithms/ShiftCalculator'
import { countAllShiftTypesInMonth, countWorkDaysInMonth, daysUntilNextRest,
  consecutiveWorkDays, getMonthlyStats } from '../main/ets/algorithms/ShiftMetrics'
import { generateMonthCalendarDays } from '../main/ets/algorithms/CalendarGenerator'
import { findBestLeavePlans } from '../main/ets/algorithms/LeaveOptimizer'
import { findCommonRestDays } from '../main/ets/algorithms/ColleagueMode'
import { HolidayData } from '../main/ets/algorithms/HolidayData'
import { ShiftType, DEFAULT_SHIFT_CYCLE, DEFAULT_REFERENCE_DATE, TOTAL_TEAMS } from '../main/ets/constants/ShiftConstants'

export default function algorithmTest() {
  describe('ShiftCalculator', () => {
    const REF = new Date(DEFAULT_REFERENCE_DATE + 'T00:00:00')

    it('refDateIsDay1Morning', 0, () => {
      const info = getShiftInfo(REF, 1)
      expect(info.dayOfCycle).assertEqual(1)
      expect(info.shiftType).assertEqual(ShiftType.MORNING)
    })

    it('refDatePlus41IsDay42Rest', 0, () => {
      const d = new Date(2025, 11, 15)
      d.setDate(d.getDate() + 41)
      const info = getShiftInfo(d, 1)
      expect(info.dayOfCycle).assertEqual(42)
      expect(info.shiftType).assertEqual(ShiftType.REST)
    })

    it('cycleWrapsAt42', 0, () => {
      const d = new Date(2025, 11, 15)
      d.setDate(d.getDate() + 42)
      const info = getShiftInfo(d, 1)
      expect(info.dayOfCycle).assertEqual(1)
    })

    it('negativeOffsetWraps', 0, () => {
      const d = new Date(2025, 11, 14)
      const info = getShiftInfo(d, 1)
      expect(info.dayOfCycle).assertEqual(42)
    })

    it('teamPhaseOffsetFormula', 0, () => {
      expect(teamPhaseOffset(1, 42)).assertEqual(0)
      expect(teamPhaseOffset(2, 42)).assertEqual(7)
      expect(teamPhaseOffset(6, 42)).assertEqual(35)
    })

    it('daysBetweenCorrect', 0, () => {
      const a = new Date(2025, 11, 15)
      const b = new Date(2026, 0, 1)
      expect(daysBetween(a, b)).assertEqual(17)
    })

    it('isWorkDayClassification', 0, () => {
      expect(isWorkDay(ShiftType.MORNING)).assertTrue()
      expect(isWorkDay(ShiftType.AFTERNOON)).assertTrue()
      expect(isWorkDay(ShiftType.NIGHT)).assertTrue()
      expect(isWorkDay(ShiftType.REST)).assertFalse()
      expect(isWorkDay(ShiftType.STUDY)).assertFalse()
    })

    it('shiftHandoverMorningTeam1', 0, () => {
      const d = new Date(2025, 11, 15)
      const ho = shiftHandover(d, 1)
      expect(ho).assertNotNull()
      if (ho) {
        expect(ho[0]).assertEqual(3)
        expect(ho[1]).assertEqual(5)
      }
    })

    it('shiftHandoverNullOnRestDay', 0, () => {
      const d = new Date(2025, 11, 19)
      const ho = shiftHandover(d, 1)
      expect(ho).assertNull()
    })
  })

  describe('ShiftMetrics', () => {
    it('daysUntilNextRestZeroForRestTomorrow', 0, () => {
      const d = new Date(2025, 11, 18)
      expect(daysUntilNextRest(d, 1)).assertEqual(0)
    })

    it('daysUntilNextRestTwoForRestIn3Days', 0, () => {
      const d = new Date(2026, 5, 28)
      expect(daysUntilNextRest(d, 1)).assertEqual(2)
    })

    it('consecutiveWorkDaysCountsBackwards', 0, () => {
      const d = new Date(2026, 5, 28)
      expect(consecutiveWorkDays(d, 1)).assertEqual(1)
    })

    it('countAllShiftTypesSumsToMonthDays', 0, () => {
      const counts = countAllShiftTypesInMonth(2026, 6, 1)
      let total = 0
      counts.forEach((v) => { total += v })
      expect(total).assertEqual(30)
    })

    it('countWorkDaysExcludesRestAndStudy', 0, () => {
      const work = countWorkDaysInMonth(2026, 6, 1)
      const counts = countAllShiftTypesInMonth(2026, 6, 1)
      const expected = (counts.get(ShiftType.MORNING) || 0) +
        (counts.get(ShiftType.AFTERNOON) || 0) +
        (counts.get(ShiftType.NIGHT) || 0)
      expect(work).assertEqual(expected)
    })
  })

  describe('CalendarGenerator', () => {
    it('generates42Cells', 0, () => {
      const days = generateMonthCalendarDays(2026, 6, 1)
      expect(days.length).assertEqual(42)
    })

    it('currentMonthDaysCorrect', 0, () => {
      const days = generateMonthCalendarDays(2026, 6, 1)
      const currentDays = days.filter(d => d.isCurrentMonth)
      expect(currentDays.length).assertEqual(30)
    })
  })

  describe('LeaveOptimizer', () => {
    it('returnsNonEmptyPlans', 0, () => {
      const plans = findBestLeavePlans(1, 5)
      expect(plans.length > 0).assertTrue()
    })

    it('minLeaveDaysIs2WhenMaxIs5', 0, () => {
      const plans = findBestLeavePlans(1, 5)
      const minLeave = plans.reduce((m, p) => Math.min(m, p.leaveDays), 99)
      expect(minLeave).assertEqual(2)
    })

    it('sortedByScoreDesc', 0, () => {
      const plans = findBestLeavePlans(1, 5)
      for (let i = 1; i < plans.length; i++) {
        expect(plans[i - 1].score >= plans[i].score).assertTrue()
      }
    })

    it('efficiencyIsTotalBreakOverLeaveDays', 0, () => {
      const plans = findBestLeavePlans(1, 5)
      for (const p of plans) {
        expect(p.efficiency).assertEqual(p.totalBreakDays / p.leaveDays)
      }
    })
  })

  describe('ColleagueMode', () => {
    it('sameTeamAllRestDaysAreCommon', 0, () => {
      const result = findCommonRestDays(1, 1)
      expect(result.totalCount > 0).assertTrue()
    })

    it('nextDateIsFirstCommonRest', 0, () => {
      const result = findCommonRestDays(1, 3)
      if (result.commonRestDates.length > 0) {
        expect(result.nextCommonRestDate).assertEqual(result.commonRestDates[0])
      }
    })

    it('count30LeCount60', 0, () => {
      const result = findCommonRestDays(1, 3)
      expect(result.countIn30Days <= result.countIn60Days).assertTrue()
    })
  })

  describe('HolidayData', () => {
    it('midAutumn2026IsSep25', 0, () => {
      expect(HolidayData.isHoliday('2026-09-25')).assertTrue()
    })

    it('midAutumn2026NotOct08', 0, () => {
      expect(HolidayData.isHoliday('2026-10-08')).assertFalse()
    })

    it('springFestival2026StartsFeb15', 0, () => {
      expect(HolidayData.isHoliday('2026-02-15')).assertTrue()
    })

    it('adjustedWorkDayIsNotHoliday', 0, () => {
      expect(HolidayData.isHoliday('2026-02-14')).assertFalse()
      expect(HolidayData.getHolidayInfo('2026-02-14')).assertNotNull()
    })

    it('nationalDayAdjustmentOverridesMidAutumn', 0, () => {
      const info = HolidayData.getHolidayInfo('2026-09-27')
      expect(info).assertNotNull()
      if (info) {
        expect(info.isHoliday).assertFalse()
      }
    })
  })
}
