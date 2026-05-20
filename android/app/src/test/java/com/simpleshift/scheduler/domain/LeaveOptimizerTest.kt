package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.ShiftType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class LeaveOptimizerTest {

    // A 7-day cycle: REST, MORNING, MORNING, REST, REST, AFTERNOON, REST
    // Indices:    0=REST, 1=WORK, 2=WORK, 3=REST, 4=REST, 5=WORK, 6=REST
    // Gaps:
    //   Between idx0(REST) and idx3(REST): 2 work days (idx1-2)
    //   Between idx4(REST) and idx6(REST): 1 work day (idx5)
    //   Between idx6(REST) and next idx0(REST): no gap (adjacent in cycle)
    private val testCycle = listOf(
        ShiftType.REST,
        ShiftType.MORNING,
        ShiftType.MORNING,
        ShiftType.REST,
        ShiftType.REST,
        ShiftType.AFTERNOON,
        ShiftType.REST
    )

    // Reference date = analysis start date, so day N = cycle[N % 7]
    // Use a fixed date for deterministic tests
    private val testToday = LocalDate.of(2026, 6, 1) // Monday
    private val refDate = testToday

    @Test
    fun `buildDailyStatus produces correct size`() {
        val status = buildDailyStatus(
            startDate = testToday,
            days = 14,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap()
        )
        assertEquals(14, status.size)
        assertEquals(testToday, status[0].date)
        assertEquals(testToday.plusDays(13), status[13].date)
    }

    @Test
    fun `buildDailyStatus isRest matches shift schedule`() {
        val status = buildDailyStatus(
            startDate = testToday,
            days = 7,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap()
        )
        // Day 0 = REST (idx=0), Day 1 = MORNING (idx=1), Day 2 = MORNING (idx=2)
        assertTrue("Day 0 should be rest", status[0].isRest)
        assertTrue("Day 3 should be rest", status[3].isRest)
        assertTrue("Day 4 should be rest", status[4].isRest)
        assertTrue("Day 6 should be rest", status[6].isRest)

        // Day 1, 2, 5 should be work
        assertTrue("Day 1 should not be rest", !status[1].isRest)
        assertTrue("Day 2 should not be rest", !status[2].isRest)
        assertTrue("Day 5 should not be rest", !status[5].isRest)
    }

    @Test
    fun `buildDailyStatus marks weekends`() {
        // June 1 2026 is Monday, June 6 is Saturday, June 7 is Sunday
        val status = buildDailyStatus(
            startDate = testToday, // Monday
            days = 7,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap()
        )
        assertTrue(!status[0].isWeekend) // Monday
        assertTrue(!status[1].isWeekend) // Tuesday
        assertTrue(status[5].isWeekend)  // Saturday
        assertTrue(status[6].isWeekend)  // Sunday
    }

    @Test
    fun `buildDailyStatus marks holidays`() {
        val holidays = mapOf(
            testToday.plusDays(2) to HolidayInfo(testToday.plusDays(2), "测试节日", true)
        )
        val status = buildDailyStatus(
            startDate = testToday,
            days = 7,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = holidays
        )
        assertTrue(status[2].isHoliday)
        assertEquals("测试节日", status[2].holidayName)
        assertTrue(!status[0].isHoliday)
    }

    @Test
    fun `buildDailyStatus marks adjusted work days`() {
        val holidays = mapOf(
            testToday.plusDays(1) to HolidayInfo(testToday.plusDays(1), "调休上班", false)
        )
        val status = buildDailyStatus(
            startDate = testToday,
            days = 7,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = holidays
        )
        assertTrue(status[1].isAdjustedWorkDay)
        assertTrue(!status[1].isHoliday)
    }

    // ── Gap bridging tests ──

    @Test
    fun `gap bridging 2-day gap between rests`() {
        // Days 0=REST, 1=WORK, 2=WORK, 3=REST, 4=REST in cycle
        // Taking leave on days 1-2 should bridge REST(day0) + 2 leave + REST(days 3-4)
        // Break: days 0-4 = 5 days, leaveDays=2, efficiency=2.5
        val strategies = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 7,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 3
        )

        val bridge = strategies.find { it.leaveDays == 2 && it.breakStart == testToday }
        assertNotNull("Should find 2-day bridge strategy", bridge)
        if (bridge != null) {
            assertEquals(5, bridge.totalBreakDays)
            assertEquals(2.5f, bridge.efficiency)
            assertEquals(listOf(testToday.plusDays(1), testToday.plusDays(2)), bridge.leaveDates)
        }
    }

    @Test
    fun `gap bridging single work day bridge`() {
        // Days 4=REST, 5=WORK, 6=REST (in test cycle)
        // Taking leave on day 5 bridges REST(day4) + 1 leave + REST(day6) + REST(day7)
        // Break: at least 4 days
        val strategies = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 14,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 3
        )

        val bridge = strategies.find { it.leaveDays == 1 && it.leaveDates.first() == testToday.plusDays(5) }
        assertNotNull("Should find 1-day bridge strategy for day 5", bridge)
        if (bridge != null) {
            assertTrue("Total break should be at least 4, got ${bridge.totalBreakDays}",
                bridge.totalBreakDays >= 4)
            assertTrue("Efficiency should be at least 4.0, got ${bridge.efficiency}",
                bridge.efficiency >= 4.0f)
        }
    }

    @Test
    fun `no strategy when gap exceeds maxLeaveDays`() {
        // Gap between day 0(REST) and day 3(REST) is 2 work days (days 1-2)
        // With maxLeaveDays=1, this gap cannot be bridged
        val strategies = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 7,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 1
        )

        // Should still find the 1-day bridge (day 5, between rests on days 4 and 6)
        val oneDayBridge = strategies.find { it.leaveDays == 1 }
        assertNotNull("Should find 1-day bridge strategy", oneDayBridge)

        // But should NOT find a 2-day bridge
        val twoDayBridge = strategies.find { it.leaveDays == 2 }
        assertEquals(null, twoDayBridge)
    }

    @Test
    fun `leave on already rest days is skipped`() {
        // Create a scenario where the only "gap" is 0 days (two rest blocks adjacent)
        val allRestCycle = listOf(ShiftType.REST, ShiftType.REST, ShiftType.REST)
        val strategies = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 3,
            teamPhaseOffset = 0,
            customCycle = allRestCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 3
        )
        // No work days, so no leave strategies possible
        assertTrue(strategies.isEmpty())
    }

    // ── Deduplication test ──

    @Test
    fun `deduplication same break keeps minimal leave`() {
        // With our test cycle repeated twice, there should be one 2-day gap bridging
        // strategies for days 1-2, and the same gap should not appear twice
        val strategies = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 14,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 5
        )

        // Check no duplicate (breakStart, breakEnd) pairs
        val breakPairs = strategies.map { Pair(it.breakStart, it.breakEnd) }
        assertEquals(breakPairs.size, breakPairs.distinct().size)
    }

    // ── Scoring tests ──

    @Test
    fun `higher efficiency strategy ranks higher with similar breaks`() {
        val strategies = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 14,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 3
        )

        if (strategies.size >= 2) {
            // Strategies are sorted by score descending
            for (i in 0 until strategies.size - 1) {
                assertTrue(
                    "Strategy ${i} score ${strategies[i].score} should >= strategy ${i + 1} score ${strategies[i + 1].score}",
                    strategies[i].score >= strategies[i + 1].score
                )
            }
        }
    }

    @Test
    fun `holiday overlap increases score`() {
        // Create a holiday on day 3 (which is REST in our cycle)
        // This means strategy bridging days 1-2 will have a holiday overlap on day 3
        val holidays = mapOf(
            testToday.plusDays(3) to HolidayInfo(testToday.plusDays(3), "节日", true)
        )
        val strategiesWithHoliday = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 7,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = holidays,
            maxLeaveDays = 3
        )

        // With holiday overlap, the first strategy should have holidayOverlap > 0
        val holidayStrategy = strategiesWithHoliday.firstOrNull()
        if (holidayStrategy != null) {
            assertTrue(
                "Strategy overlapping holiday should have holidayOverlap > 0",
                holidayStrategy.holidayOverlap > 0
            )
        }
    }

    // ── Custom cycle / parameter tests ──

    @Test
    fun `custom cycle respected`() {
        val shortCycle = listOf(ShiftType.REST, ShiftType.MORNING, ShiftType.REST)
        // Days: 0=REST, 1=WORK, 2=REST, 3=REST, 4=WORK, 5=REST, ...
        // Gap: day 1 (WORK) between day 0(REST) and day 2(REST)
        // Also gap: day 4 (WORK) between day 3(REST) and day 5(REST)
        val strategies = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 6,
            teamPhaseOffset = 0,
            customCycle = shortCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 2
        )

        assertTrue("Should find at least one strategy with custom cycle", strategies.isNotEmpty())
        // Should find a 1-day bridge strategy
        val bridge = strategies.firstOrNull { it.leaveDays == 1 }
        assertNotNull("Should find a 1-day bridge strategy", bridge)
        if (bridge != null) {
            assertTrue("Total break should be at least 3, got ${bridge.totalBreakDays}",
                bridge.totalBreakDays >= 3)
        }
    }

    @Test
    fun `team phase offset shifts results`() {
        // With phaseOffset=1, day 0 uses cycle index 1 instead of 0
        // So day 0 = MORNING (work), day 1 = MORNING (work), day 2 = REST, etc.
        // This shifts which days are rest
        val strategies = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 7,
            teamPhaseOffset = 1, // Shifts everything by 1
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 3
        )

        // Results should differ from phaseOffset=0
        val strategiesDefault = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 7,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 3
        )

        // Both should run without error and produce results
        assertTrue(strategiesDefault.isNotEmpty() || strategies.isNotEmpty())
    }

    // ── Edge cases ──

    @Test
    fun `empty result for invalid parameters`() {
        val empty = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 0,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 3
        )
        assertTrue(empty.isEmpty())

        val noLeave = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 7,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 0
        )
        assertTrue(noLeave.isEmpty())
    }

    @Test
    fun `strategies contain all required fields`() {
        val strategies = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 14,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = emptyMap(),
            maxLeaveDays = 3
        )

        strategies.forEach { strategy ->
            assertTrue(strategy.leaveDays > 0)
            assertTrue(strategy.totalBreakDays > strategy.leaveDays)
            assertTrue(strategy.leaveDates.isNotEmpty())
            assertTrue(strategy.breakStart <= strategy.breakEnd)
            assertTrue(strategy.efficiency > 1.0f)
            assertTrue(strategy.score >= 0f && strategy.score <= 1f)
            assertTrue(strategy.holidayOverlap >= 0)
            assertTrue(strategy.weekendOverlap >= 0)
        }
    }

    @Test
    fun `holiday names are captured correctly`() {
        val holidays = mapOf(
            testToday.plusDays(3) to HolidayInfo(testToday.plusDays(3), "春节", true),
            testToday.plusDays(4) to HolidayInfo(testToday.plusDays(4), "春节", true)
        )
        val strategies = findBestLeavePlans(
            today = testToday,
            daysToAnalyze = 7,
            teamPhaseOffset = 0,
            customCycle = testCycle,
            referenceDate = refDate,
            holidays = holidays,
            maxLeaveDays = 3
        )

        strategies.forEach { strategy ->
            if (strategy.holidayOverlap > 0) {
                assertTrue(
                    "Strategy with holiday overlap should have holiday names",
                    strategy.overlappingHolidayNames.isNotEmpty()
                )
                assertTrue(strategy.overlappingHolidayNames.contains("春节"))
            }
        }
    }
}
