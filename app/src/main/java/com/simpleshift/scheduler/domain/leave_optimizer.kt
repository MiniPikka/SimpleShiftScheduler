package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.LeaveStrategy
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import java.time.LocalDate
import java.time.temporal.ChronoUnit

// ── Internal day status used during analysis ──

internal data class DayStatus(
    val date: LocalDate,
    val isRest: Boolean,
    val isHoliday: Boolean,
    val isWeekend: Boolean,
    val isAdjustedWorkDay: Boolean,
    val holidayName: String?
)

// ── Public API ──

/**
 * Finds the best leave strategies for the next [daysToAnalyze] days.
 *
 * Algorithm: Gap-merging + extension.
 * 1. Build daily status for the analysis window (shift schedule + holidays + weekends).
 * 2. Scan for work gaps (consecutive work days) and bridge them with leave.
 * 3. Also extend rest blocks by taking leave on adjacent work days.
 * 4. Score, deduplicate, and rank.
 *
 * @param today Start date for analysis (inclusive).
 * @param daysToAnalyze Number of days to look ahead (default 365).
 * @param teamPhaseOffset Team phase offset for shift calculation.
 * @param customCycle Custom shift cycle, uses default if null.
 * @param referenceDate Reference date for the shift cycle.
 * @param holidays China holiday data map (date -> info).
 * @param maxLeaveDays Maximum leave days to consider per strategy.
 */
fun findBestLeavePlans(
    today: LocalDate = LocalDate.now(),
    daysToAnalyze: Int = 365,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE,
    holidays: Map<LocalDate, HolidayInfo> = getChinaHolidays(),
    maxLeaveDays: Int = 5
): List<LeaveStrategy> {
    if (daysToAnalyze < 1 || maxLeaveDays < 1) return emptyList()

    val status = buildDailyStatus(
        startDate = today,
        days = daysToAnalyze,
        teamPhaseOffset = teamPhaseOffset,
        customCycle = customCycle,
        referenceDate = referenceDate,
        holidays = holidays
    )

    // Precompute consecutive rest before/after each index
    val n = status.size
    val restBefore = IntArray(n)
    val restAfter = IntArray(n)

    for (i in 1 until n) {
        restBefore[i] = if (status[i - 1].isRest) restBefore[i - 1] + 1 else 0
    }
    for (i in n - 2 downTo 0) {
        restAfter[i] = if (status[i + 1].isRest) restAfter[i + 1] + 1 else 0
    }

    val strategies = mutableListOf<LeaveStrategy>()

    for (leaveDays in 1..maxLeaveDays) {
        for (startIdx in 0..(n - leaveDays)) {
            // All leave days must be work days (not rest)
            if ((0 until leaveDays).any { status[startIdx + it].isRest }) continue

            // All leave days must be within the analysis window and not in the past
            // (already guaranteed by startIdx range)

            val leftRest = restBefore[startIdx]
            val rightRest = restAfter[startIdx + leaveDays - 1]

            // The break: left rest + leave days + right rest
            val totalBreak = leftRest + leaveDays + rightRest
            if (totalBreak <= leaveDays) continue // no benefit

            val gapStart = startIdx - leftRest
            val gapEnd = startIdx + leaveDays - 1 + rightRest

            val breakStartDate = status[gapStart].date
            val breakEndDate = status[gapEnd].date

            // Calculate family overlap within the break
            var holidayOverlap = 0
            var weekendOverlap = 0
            val holidayNames = mutableSetOf<String>()

            for (idx in gapStart..gapEnd) {
                val ds = status[idx]
                if (ds.isHoliday) {
                    holidayOverlap++
                    ds.holidayName?.let { holidayNames.add(it) }
                }
                if (ds.isWeekend && !ds.isAdjustedWorkDay) {
                    weekendOverlap++
                }
            }

            val leaveDateList = (startIdx until startIdx + leaveDays).map { status[it].date }

            val efficiency = totalBreak.toFloat() / leaveDays

            strategies.add(
                LeaveStrategy(
                    leaveDays = leaveDays,
                    totalBreakDays = totalBreak,
                    leaveDates = leaveDateList,
                    breakStart = breakStartDate,
                    breakEnd = breakEndDate,
                    holidayOverlap = holidayOverlap,
                    weekendOverlap = weekendOverlap,
                    overlappingHolidayNames = holidayNames.toList(),
                    efficiency = efficiency,
                    score = 0f // computed later
                )
            )
        }
    }

    // Deduplicate: same (breakStart, breakEnd) → keep the one with fewest leave days
    val deduped = strategies
        .groupBy { Pair(it.breakStart, it.breakEnd) }
        .mapValues { (_, list) -> list.minByOrNull { it.leaveDays }!! }
        .values
        .toList()

    if (deduped.isEmpty()) return emptyList()

    // Compute scores
    val maxEfficiency = deduped.maxOf { it.efficiency }
    val maxBreak = deduped.maxOf { it.totalBreakDays }
    val maxFamilyBonus = deduped.maxOf { it.holidayOverlap * 2 + it.weekendOverlap }.coerceAtLeast(1)

    val scored = deduped.map { strategy ->
        val effScore = if (maxEfficiency > 0f) strategy.efficiency / maxEfficiency else 0f
        val lenScore = if (maxBreak > 0) strategy.totalBreakDays.toFloat() / maxBreak else 0f
        val familyBonus = strategy.holidayOverlap * 2 + strategy.weekendOverlap
        val famScore = familyBonus.toFloat() / maxFamilyBonus

        val score = 0.50f * effScore + 0.25f * lenScore + 0.25f * famScore
        strategy.copy(score = score)
    }

    return scored.sortedByDescending { it.score }
}

// ── Internal helpers ──

internal fun buildDailyStatus(
    startDate: LocalDate,
    days: Int,
    teamPhaseOffset: Int,
    customCycle: List<ShiftType>?,
    referenceDate: LocalDate,
    holidays: Map<LocalDate, HolidayInfo>
): List<DayStatus> {
    return (0 until days).map { offset ->
        val date = startDate.plusDays(offset.toLong())
        val shiftType = getShiftTypeForDate(date, teamPhaseOffset, customCycle, referenceDate)
        val isRest = shiftType == ShiftType.REST || shiftType == ShiftType.STUDY
        val holidayInfo = holidays[date]
        val isHoliday = holidayInfo?.isHoliday == true
        val isAdjustedWorkDay = holidayInfo != null && !holidayInfo.isHoliday

        DayStatus(
            date = date,
            isRest = isRest,
            isHoliday = isHoliday,
            isWeekend = isWeekend(date),
            isAdjustedWorkDay = isAdjustedWorkDay,
            holidayName = if (isHoliday) holidayInfo?.name else null
        )
    }
}

/**
 * Returns the team phase offset for a given team ID and cycle.
 */
fun teamPhaseOffsetFor(teamId: Int, customCycle: List<ShiftType>? = null): Int {
    val totalDays = customCycle?.size ?: ShiftCycleConfig.CYCLE_LENGTH
    return (teamId - 1) * (totalDays / Team.TOTAL_TEAMS)
}
