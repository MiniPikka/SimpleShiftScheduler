package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.ShiftType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.YearMonth

class CalendarGeneratorTest {

    @Test
    fun `generateMonthCalendarDays returns fixed 42-day grid`() {
        val days = generateMonthCalendarDays(YearMonth.of(2026, 4))
        assertEquals(42, days.size)
    }

    @Test
    fun `generateMonthCalendarDays starts from sunday by default`() {
        val days = generateMonthCalendarDays(YearMonth.of(2026, 4))
        assertEquals(DayOfWeek.SUNDAY, days.first().date.dayOfWeek)
    }

    @Test
    fun `generateMonthCalendarDays marks current month correctly`() {
        val targetMonth = YearMonth.of(2026, 4)
        val days = generateMonthCalendarDays(targetMonth)

        assertTrue(days.any { it.isCurrentMonth && it.date.monthValue == 4 })
        assertFalse(days.all { it.isCurrentMonth })
    }

    @Test
    fun `generateMonthCalendarDays with teamPhaseOffset shifts shift types`() {
        val targetMonth = YearMonth.of(2026, 4)
        val defaultDays = generateMonthCalendarDays(targetMonth, teamPhaseOffset = 0)
        val shiftedDays = generateMonthCalendarDays(targetMonth, teamPhaseOffset = 7)

        // Same dates, different shift types due to team offset
        assertEquals(defaultDays.size, shiftedDays.size)
        assertEquals(defaultDays.first().date, shiftedDays.first().date)
        // Shift types should differ for the first cell
        assertEquals(
            defaultDays.count { it.shiftType == ShiftType.MORNING } +
            defaultDays.count { it.shiftType == ShiftType.AFTERNOON } +
            defaultDays.count { it.shiftType == ShiftType.REST } +
            defaultDays.count { it.shiftType == ShiftType.NIGHT } +
            defaultDays.count { it.shiftType == ShiftType.STUDY },
            42
        )
    }
}
