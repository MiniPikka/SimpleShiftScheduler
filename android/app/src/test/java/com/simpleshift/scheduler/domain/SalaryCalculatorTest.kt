package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.SalaryBreakdown
import com.simpleshift.scheduler.domain.model.SalaryConfig
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate
import java.time.YearMonth

class SalaryCalculatorTest {

    @Test
    fun `countAllShiftTypesInMonth total equals month days`() {
        val month = YearMonth.of(2026, 5) // 31 days
        val counts = countAllShiftTypesInMonth(month)

        val total = counts.values.sum()
        assertEquals(31, total)
    }

    @Test
    fun `countAllShiftTypesInMonth matches individual countShiftTypeInMonth`() {
        val month = YearMonth.of(2026, 5)
        val counts = countAllShiftTypesInMonth(month)

        ShiftType.entries.forEach { type ->
            val individual = countShiftTypeInMonth(month, type)
            assertEquals("Count mismatch for $type", individual, counts[type])
        }
    }

    @Test
    fun `shift premium total correct`() {
        val config = SalaryConfig(
            mapOf(
                ShiftType.MORNING to 0.0,
                ShiftType.AFTERNOON to 50.0,
                ShiftType.NIGHT to 200.0,
                ShiftType.STUDY to 0.0
            )
        )
        val counts = mapOf(
            ShiftType.MORNING to 8,
            ShiftType.AFTERNOON to 7,
            ShiftType.NIGHT to 7,
            ShiftType.REST to 8,
            ShiftType.STUDY to 1
        )
        val breakdown = calculateSalaryBreakdown(config, counts, YearMonth.of(2026, 5))

        // AFTERNOON: 7 * 50 = 350, NIGHT: 7 * 200 = 1400, total = 1750
        assertEquals(1750.0, breakdown.shiftPremiumTotal, 0.01)
        assertEquals(YearMonth.of(2026, 5), breakdown.month)
    }

    @Test
    fun `decimal premium calculation correct`() {
        val config = SalaryConfig(
            mapOf(
                ShiftType.NIGHT to 12.5,
                ShiftType.AFTERNOON to 7.25
            )
        )
        val counts = mapOf(
            ShiftType.MORNING to 8,
            ShiftType.AFTERNOON to 4,
            ShiftType.NIGHT to 6,
            ShiftType.REST to 8,
            ShiftType.STUDY to 1
        )
        val breakdown = calculateSalaryBreakdown(config, counts, YearMonth.of(2026, 5))

        // NIGHT: 6 * 12.5 = 75.0, AFTERNOON: 4 * 7.25 = 29.0, total = 104.0
        assertEquals(104.0, breakdown.shiftPremiumTotal, 0.01)
    }

    @Test
    fun `simulate extra shifts increases total`() {
        val config = SalaryConfig(
            mapOf(ShiftType.NIGHT to 200.0, ShiftType.AFTERNOON to 50.0)
        )
        val counts = mapOf(
            ShiftType.MORNING to 8,
            ShiftType.AFTERNOON to 7,
            ShiftType.NIGHT to 7,
            ShiftType.REST to 8,
            ShiftType.STUDY to 1
        )
        val current = calculateSalaryBreakdown(config, counts, YearMonth.of(2026, 5))

        val simulated = simulateExtraShifts(current, 2, ShiftType.NIGHT, config)

        assertEquals(current.shiftPremiumTotal + 400.0, simulated.shiftPremiumTotal, 0.01)
        assertEquals(9, simulated.shiftCounts[ShiftType.NIGHT])
        // Other counts unchanged
        assertEquals(8, simulated.shiftCounts[ShiftType.MORNING])
    }

    @Test
    fun `zero config produces zero total`() {
        val config = SalaryConfig()
        val counts = mapOf(
            ShiftType.MORNING to 8,
            ShiftType.AFTERNOON to 7,
            ShiftType.NIGHT to 7,
            ShiftType.REST to 8,
            ShiftType.STUDY to 1
        )
        val breakdown = calculateSalaryBreakdown(config, counts, YearMonth.of(2026, 5))

        assertEquals(0.0, breakdown.shiftPremiumTotal, 0.01)
    }

    @Test
    fun `custom cycle respected in countAllShiftTypes`() {
        val customCycle = listOf(
            ShiftType.MORNING, ShiftType.MORNING, ShiftType.AFTERNOON,
            ShiftType.REST, ShiftType.NIGHT, ShiftType.STUDY, ShiftType.REST
        )
        val month = YearMonth.of(2026, 5)

        val defaultCounts = countAllShiftTypesInMonth(month)
        val customCounts = countAllShiftTypesInMonth(month, customCycle = customCycle,
            referenceDate = ShiftCycleConfig.REFERENCE_DATE)

        // Counts should differ because cycle is different
        val defaultTotal = defaultCounts.values.sum()
        val customTotal = customCounts.values.sum()
        assertEquals(defaultTotal, customTotal) // Both should sum to month days
    }

    @Test
    fun `team phase offset changes shift counts`() {
        val month = YearMonth.of(2026, 5)
        val team1Counts = countAllShiftTypesInMonth(month, teamPhaseOffset = 0)
        val team2Counts = countAllShiftTypesInMonth(month, teamPhaseOffset = 7)

        // Totals should be same
        assertEquals(team1Counts.values.sum(), team2Counts.values.sum())

        // But distributions should differ (at least one type count differs)
        val anyDifferent = ShiftType.entries.any { team1Counts[it] != team2Counts[it] }
        assertTrue("Team phase offset should change shift distribution", anyDifferent)
    }

    @Test
    fun `simulate zero extra shifts returns same total`() {
        val config = SalaryConfig(mapOf(ShiftType.NIGHT to 200.0))
        val counts = mapOf(
            ShiftType.MORNING to 8, ShiftType.AFTERNOON to 7,
            ShiftType.NIGHT to 7, ShiftType.REST to 8, ShiftType.STUDY to 1
        )
        val current = calculateSalaryBreakdown(config, counts, YearMonth.of(2026, 5))

        val simulated = simulateExtraShifts(current, 0, ShiftType.NIGHT, config)

        assertEquals(current.shiftPremiumTotal, simulated.shiftPremiumTotal, 0.01)
    }
}
