package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import org.junit.Assert.assertEquals
import org.junit.Test

class ShiftCalculatorTest {

    @Test
    fun `calculateDayOffset returns expected offsets`() {
        val reference = ShiftCycleConfig.REFERENCE_DATE

        assertEquals(0, calculateDayOffset(reference))
        assertEquals(1, calculateDayOffset(reference.plusDays(1)))
        assertEquals(42, calculateDayOffset(reference.plusDays(42)))
        assertEquals(-1, calculateDayOffset(reference.minusDays(1)))
    }

    @Test
    fun `normalizeCycleIndex handles positive and negative offsets`() {
        assertEquals(0, normalizeCycleIndex(0))
        assertEquals(1, normalizeCycleIndex(1))
        assertEquals(41, normalizeCycleIndex(41))
        assertEquals(0, normalizeCycleIndex(42))
        assertEquals(41, normalizeCycleIndex(-1))
    }

    @Test
    fun `getShiftTypeForDate returns correct shift by cycle index`() {
        val reference = ShiftCycleConfig.REFERENCE_DATE

        assertEquals(ShiftType.MORNING, getShiftTypeForDate(reference.plusDays(0)))
        assertEquals(ShiftType.MORNING, getShiftTypeForDate(reference.plusDays(1)))
        assertEquals(ShiftType.AFTERNOON, getShiftTypeForDate(reference.plusDays(2)))
        assertEquals(ShiftType.AFTERNOON, getShiftTypeForDate(reference.plusDays(3)))
        assertEquals(ShiftType.REST, getShiftTypeForDate(reference.plusDays(4)))
        assertEquals(ShiftType.REST, getShiftTypeForDate(reference.plusDays(40)))
        assertEquals(ShiftType.REST, getShiftTypeForDate(reference.plusDays(41)))
    }

    @Test
    fun `getShiftInfo returns day of cycle and shift type`() {
        val reference = ShiftCycleConfig.REFERENCE_DATE

        val day1 = getShiftInfo(reference)
        assertEquals(1, day1.dayOfCycle)
        assertEquals(ShiftType.MORNING, day1.shiftType)

        val day5 = getShiftInfo(reference.plusDays(4))
        assertEquals(5, day5.dayOfCycle)
        assertEquals(ShiftType.REST, day5.shiftType)

        val day42 = getShiftInfo(reference.plusDays(41))
        assertEquals(42, day42.dayOfCycle)
        assertEquals(ShiftType.REST, day42.shiftType)
    }

    @Test
    fun `getShiftTypeForDate with teamPhaseOffset 7 returns shifted shift`() {
        val reference = ShiftCycleConfig.REFERENCE_DATE

        // Team 2 (offset 7): on reference date, should show what Team 1 shows 7 days later
        assertEquals(ShiftType.REST, getShiftTypeForDate(reference, teamPhaseOffset = 7))

        // Team 3 (offset 14)
        assertEquals(ShiftType.NIGHT, getShiftTypeForDate(reference, teamPhaseOffset = 14))

        // Team 6 (offset 35)
        assertEquals(ShiftType.STUDY, getShiftTypeForDate(reference, teamPhaseOffset = 35))
    }

    @Test
    fun `getShiftInfo with teamPhaseOffset returns correct day of cycle`() {
        val reference = ShiftCycleConfig.REFERENCE_DATE

        val info = getShiftInfo(reference, teamPhaseOffset = 7)
        assertEquals(8, info.dayOfCycle)
        assertEquals(ShiftType.REST, info.shiftType)
    }

    @Test
    fun `getShiftInfo with custom cycle returns correct results`() {
        val reference = ShiftCycleConfig.REFERENCE_DATE
        val customCycle = listOf(ShiftType.NIGHT, ShiftType.MORNING, ShiftType.REST)

        val info = getShiftInfo(reference, customCycle = customCycle)
        assertEquals(1, info.dayOfCycle)
        assertEquals(ShiftType.NIGHT, info.shiftType)

        val info2 = getShiftInfo(reference.plusDays(1), customCycle = customCycle)
        assertEquals(2, info2.dayOfCycle)
        assertEquals(ShiftType.MORNING, info2.shiftType)

        val info3 = getShiftInfo(reference.plusDays(3), customCycle = customCycle)
        assertEquals(1, info3.dayOfCycle)
        assertEquals(ShiftType.NIGHT, info3.shiftType)
    }

    @Test
    fun `getShiftInfo with custom cycle boundary of 1 day`() {
        val reference = ShiftCycleConfig.REFERENCE_DATE
        val customCycle = listOf(ShiftType.STUDY)

        val info = getShiftInfo(reference, customCycle = customCycle)
        assertEquals(1, info.dayOfCycle)
        assertEquals(ShiftType.STUDY, info.shiftType)

        val info2 = getShiftInfo(reference.plusDays(1), customCycle = customCycle)
        assertEquals(1, info2.dayOfCycle)
        assertEquals(ShiftType.STUDY, info2.shiftType)
    }

    @Test
    fun `getShiftInfo with null customCycle falls back to default`() {
        val reference = ShiftCycleConfig.REFERENCE_DATE

        val withNull = getShiftInfo(reference, customCycle = null)
        val default = getShiftInfo(reference)

        assertEquals(default.dayOfCycle, withNull.dayOfCycle)
        assertEquals(default.shiftType, withNull.shiftType)
    }
}
