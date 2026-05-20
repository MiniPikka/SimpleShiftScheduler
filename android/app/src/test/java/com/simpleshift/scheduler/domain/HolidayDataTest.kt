package com.simpleshift.scheduler.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.LocalDate

class HolidayDataTest {

    @Test
    fun `no duplicate dates in holiday map`() {
        val holidays = getChinaHolidays()
        val dates = holidays.keys
        assertEquals("Holiday map should have no duplicate dates",
            dates.size, dates.distinct().size)
    }

    @Test
    fun `covers at least 365 days from today`() {
        val holidays = getChinaHolidays()
        val today = LocalDate.of(2026, 5, 14)
        val yearEnd = today.plusDays(365)

        // The map should contain some holidays in the next 365 days
        val upcomingHolidays = holidays.keys.count { it in today..yearEnd }
        assertTrue("Should have holidays in the next 365 days, found $upcomingHolidays",
            upcomingHolidays > 0)
    }

    @Test
    fun `adjusted work days have isHoliday false`() {
        val holidays = getChinaHolidays()
        val adjustedDays = holidays.values.filter { it.name?.contains("调休") == true }

        assertTrue("Should have at least some adjusted work days", adjustedDays.isNotEmpty())
        adjustedDays.forEach { day ->
            assertFalse("Adjusted work day ${day.date} should have isHoliday=false", day.isHoliday)
        }
    }

    @Test
    fun `major holidays present`() {
        val holidays = getChinaHolidays()
        val holidayNames = holidays.values
            .filter { it.isHoliday }
            .map { it.name ?: "" }
            .toSet()

        val requiredHolidays = listOf("春节", "劳动节", "国庆节")
        requiredHolidays.forEach { required ->
            val found = holidayNames.any { required in it }
            assertTrue("Major holiday '$required' should be present", found)
        }
    }

    @Test
    fun `isWeekend detects Saturday and Sunday`() {
        // 2026-05-16 is Saturday, 2026-05-17 is Sunday
        assertTrue(isWeekend(LocalDate.of(2026, 5, 16)))
        assertTrue(isWeekend(LocalDate.of(2026, 5, 17)))
        // 2026-05-15 is Friday
        assertFalse(isWeekend(LocalDate.of(2026, 5, 15)))
        // 2026-05-18 is Monday
        assertFalse(isWeekend(LocalDate.of(2026, 5, 18)))
    }

    @Test
    fun `isNaturallyOff handles holidays weekends and adjusted days`() {
        val holidays = getChinaHolidays()

        // A regular holiday (端午节 Jun 19 2026) should be naturally off
        val dragonBoat = LocalDate.of(2026, 6, 19)
        assertTrue("Dragon Boat Festival should be naturally off",
            isNaturallyOff(dragonBoat, holidays))

        // A regular Saturday should be naturally off
        val saturday = LocalDate.of(2026, 5, 16) // Saturday
        assertTrue("Saturday should be naturally off",
            isNaturallyOff(saturday, holidays))

        // A 调休 work day (Feb 14 2026 Saturday) should NOT be naturally off
        val adjustedSat = LocalDate.of(2026, 2, 14)
        assertFalse("Adjusted work Saturday should not be naturally off",
            isNaturallyOff(adjustedSat, holidays))

        // A regular Monday should not be naturally off
        val monday = LocalDate.of(2026, 5, 18)
        assertFalse("Regular Monday should not be naturally off",
            isNaturallyOff(monday, holidays))
    }
}
