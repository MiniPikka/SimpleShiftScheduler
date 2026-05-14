package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.ShiftType
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate
import java.time.YearMonth

class ShiftMetricsTest {

    private val twoDayCycle = listOf(ShiftType.MORNING, ShiftType.REST)

    @Test
    fun `countShiftTypeInMonth 2-day cycle Feb 2026 REST`() {
        val ym = YearMonth.of(2026, 2)
        assertEquals(14, countShiftTypeInMonth(ym, ShiftType.REST, customCycle = twoDayCycle))
    }

    @Test
    fun `countShiftTypeInMonth 2-day cycle Feb 2026 MORNING`() {
        val ym = YearMonth.of(2026, 2)
        assertEquals(14, countShiftTypeInMonth(ym, ShiftType.MORNING, customCycle = twoDayCycle))
    }

    @Test
    fun `countWorkDaysInMonth 2-day cycle Feb 2026`() {
        val ym = YearMonth.of(2026, 2)
        assertEquals(14, countWorkDaysInMonth(ym, customCycle = twoDayCycle))
    }

    @Test
    fun `consecutiveWorkDays backtracks correctly`() {
        val today = LocalDate.of(2025, 12, 15) // offset 0 = MORNING
        assertEquals(1, consecutiveWorkDays(today, customCycle = twoDayCycle))
    }

    @Test
    fun `consecutiveWorkDays returns 0 when today is REST`() {
        val today = LocalDate.of(2025, 12, 16) // offset 1 = REST
        assertEquals(0, consecutiveWorkDays(today, customCycle = twoDayCycle))
    }

    @Test
    fun `consecutiveWorkDays returns 0 when today is STUDY`() {
        val studyCycle = listOf(ShiftType.STUDY, ShiftType.MORNING)
        val today = LocalDate.of(2025, 12, 15)
        assertEquals(0, consecutiveWorkDays(today, customCycle = studyCycle))
    }

    @Test
    fun `daysUntilNextRest returns 0 when tomorrow is REST`() {
        val today = LocalDate.of(2025, 12, 15) // MORNING, tomorrow REST
        assertEquals(0, daysUntilNextRest(today, customCycle = twoDayCycle))
    }

    @Test
    fun `daysUntilNextRest when today is REST searches from tomorrow`() {
        val today = LocalDate.of(2025, 12, 16) // REST, tomorrow MORNING, next REST the day after
        assertEquals(1, daysUntilNextRest(today, customCycle = twoDayCycle))
    }

    @Test
    fun `daysUntilNextRest returns 0 when no REST in cycle`() {
        val allWork = listOf(ShiftType.MORNING)
        val today = LocalDate.of(2025, 12, 15)
        assertEquals(0, daysUntilNextRest(today, customCycle = allWork))
    }

    @Test
    fun `countWorkDaysInMonth all work returns full month`() {
        val ym = YearMonth.of(2026, 2)
        assertEquals(28, countWorkDaysInMonth(ym, customCycle = listOf(ShiftType.MORNING)))
    }

    @Test
    fun `countWorkDaysInMonth all REST returns 0`() {
        val ym = YearMonth.of(2026, 2)
        assertEquals(0, countWorkDaysInMonth(ym, customCycle = listOf(ShiftType.REST)))
    }

    @Test
    fun `countWorkDaysInMonth STUDY is not work`() {
        val ym = YearMonth.of(2026, 2)
        assertEquals(0, countWorkDaysInMonth(ym, customCycle = listOf(ShiftType.STUDY)))
    }

    @Test
    fun `countWorkDaysInMonth NIGHT is work`() {
        val ym = YearMonth.of(2026, 2)
        assertEquals(28, countWorkDaysInMonth(ym, customCycle = listOf(ShiftType.NIGHT)))
    }

    @Test
    fun `countShiftTypeInMonth with default cycle returns valid count`() {
        val ym = YearMonth.of(2026, 2)
        // Just verify it doesn't crash and returns something in valid range
        val count = countShiftTypeInMonth(ym, ShiftType.REST)
        assert(count in 0..28) { "REST count should be 0..28, was $count" }
    }

    @Test
    fun `countWorkDaysInMonth with default cycle returns valid count`() {
        val ym = YearMonth.of(2026, 2)
        val count = countWorkDaysInMonth(ym)
        assert(count in 0..28) { "Work days should be 0..28, was $count" }
    }
}
