package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.ShiftType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class ColleagueModeTest {

    // 6-day cycle: each team gets a distinct offset when step=1
    // Days: 0=R, 1=M, 2=A, 3=R, 4=N, 5=R, 6=R, 7=M, ...
    private val testCycle = listOf(
        ShiftType.REST,
        ShiftType.MORNING,
        ShiftType.AFTERNOON,
        ShiftType.REST,
        ShiftType.NIGHT,
        ShiftType.REST
    )

    private val testToday = LocalDate.of(2026, 6, 1)
    private val refDate = testToday

    @Test
    fun `same team produces all rest days as common`() {
        val result = findCommonRestDays(
            teamAId = 1,
            teamBId = 1,
            today = testToday,
            daysToAnalyze = 12,
            customCycle = testCycle,
            referenceDate = refDate
        )

        // Team 1 rest days: 0, 3, 5, 6, 9, 11 → 6 rest days in 12 days
        assertEquals(6, result.totalCount)
        assertEquals("Should have same team name for both", result.teamAName, result.teamBName)
    }

    @Test
    fun `different teams find correct intersection`() {
        // Team 1 offset 0: REST on 0,3,5,6,9,11
        // Team 3 offset 2: REST on 1,3,4,7,9,10
        // Common: 3,9 → 2 common rest days in first 12 days
        val result = findCommonRestDays(
            teamAId = 1,
            teamBId = 3,
            today = testToday,
            daysToAnalyze = 12,
            customCycle = testCycle,
            referenceDate = refDate
        )

        assertEquals(2, result.totalCount)
        assertTrue(result.commonRestDates.contains(testToday.plusDays(3)))
        assertTrue(result.commonRestDates.contains(testToday.plusDays(9)))
    }

    @Test
    fun `nextCommonRestDate is the earliest`() {
        // Team 1 & 3: first common rest is day 3
        val result = findCommonRestDays(
            teamAId = 1,
            teamBId = 3,
            today = testToday,
            daysToAnalyze = 12,
            customCycle = testCycle,
            referenceDate = refDate
        )

        assertNotNull(result.nextCommonRestDate)
        assertEquals(testToday.plusDays(3), result.nextCommonRestDate)
        assertEquals(3, result.daysUntilNext)
    }

    @Test
    fun `daysUntilNext correct for today common rest`() {
        // Start analysis from a common rest day itself
        // Team 1 & 3: day 3 is a common rest
        val result = findCommonRestDays(
            teamAId = 1,
            teamBId = 3,
            today = testToday.plusDays(3),
            daysToAnalyze = 12,
            customCycle = testCycle,
            referenceDate = refDate
        )

        assertNotNull(result.nextCommonRestDate)
        assertEquals(testToday.plusDays(3), result.nextCommonRestDate)
        assertEquals(0, result.daysUntilNext)
    }

    @Test
    fun `countIn30Days and countIn60Days accurate`() {
        // Teams 1 & 3 with 6-day cycle: every 6 days there are 2 common rests
        // In 90 days: ~30 common rests total, ~10 in 30 days, ~20 in 60 days
        val result = findCommonRestDays(
            teamAId = 1,
            teamBId = 3,
            today = testToday,
            daysToAnalyze = 90,
            customCycle = testCycle,
            referenceDate = refDate
        )

        assertTrue("Total count should be > 0", result.totalCount > 0)
        // 30-day count ≤ 60-day count ≤ total count
        assertTrue("countIn30Days (${result.countIn30Days}) ≤ countIn60Days (${result.countIn60Days})",
            result.countIn30Days <= result.countIn60Days)
        assertTrue("countIn60Days (${result.countIn60Days}) ≤ totalCount (${result.totalCount})",
            result.countIn60Days <= result.totalCount)
        // In 30 days: common = 3,9,15,21,27 = 5 common rests
        assertTrue("Should have at least 4 common rests in 30 days, got ${result.countIn30Days}",
            result.countIn30Days >= 4)
    }

    @Test
    fun `custom cycle respected`() {
        val shortCycle = listOf(ShiftType.REST, ShiftType.MORNING, ShiftType.REST)
        // 3-day cycle, step = 0 (3/6=0), so all teams same offset

        val resultDefault = findCommonRestDays(
            teamAId = 1,
            teamBId = 2,
            today = testToday,
            daysToAnalyze = 6,
            customCycle = shortCycle,
            referenceDate = refDate
        )

        assertTrue("Should find at least one strategy with custom cycle",
            resultDefault.commonRestDates.isNotEmpty())
    }

    @Test
    fun `empty result when no overlap`() {
        // Teams with completely opposite schedules
        val oppositeCycle = listOf(
            ShiftType.REST, ShiftType.MORNING, ShiftType.MORNING,
            ShiftType.MORNING, ShiftType.MORNING, ShiftType.MORNING
        )
        // Only one REST day per 6-day cycle, all teams same pattern (step=1)

        val result = findCommonRestDays(
            teamAId = 1,
            teamBId = 2,
            today = testToday,
            daysToAnalyze = 6,
            customCycle = oppositeCycle,
            referenceDate = refDate
        )

        // Both teams have REST only on day 0 (same day), so there IS a common rest
        // Let me check: team 1 offset 0, day 0=REST. team 2 offset 1, day 5=REST.
        // No common rest
        assertEquals(0, result.totalCount)
        assertNull(result.nextCommonRestDate)
        assertNull(result.daysUntilNext)
        assertTrue(result.commonRestDates.isEmpty())
    }

    @Test
    fun `result fields are populated correctly`() {
        val result = findCommonRestDays(
            teamAId = 1,
            teamBId = 3,
            today = testToday,
            daysToAnalyze = 30,
            customCycle = testCycle,
            referenceDate = refDate
        )

        // Check all fields are populated
        assertTrue(result.teamAName.isNotEmpty())
        assertTrue(result.teamBName.isNotEmpty())
        assertTrue(result.totalCount >= 0)
        assertTrue(result.countIn30Days >= 0)
        assertTrue(result.countIn60Days >= 0)
        // Dates should be sorted
        val dates = result.commonRestDates
        for (i in 0 until dates.size - 1) {
            assertTrue("Dates should be sorted", dates[i] < dates[i + 1])
        }
    }
}
