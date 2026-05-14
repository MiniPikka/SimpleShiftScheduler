package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.CommonRestResult
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import java.time.LocalDate
import java.time.temporal.ChronoUnit

fun findCommonRestDays(
    teamAId: Int,
    teamBId: Int,
    today: LocalDate = LocalDate.now(),
    daysToAnalyze: Int = 365,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
): CommonRestResult {
    val offsetA = teamPhaseOffsetFor(teamAId, customCycle)
    val offsetB = teamPhaseOffsetFor(teamBId, customCycle)
    val teamAName = Team.ALL_TEAMS.find { it.id == teamAId }?.name ?: "班组$teamAId"
    val teamBName = Team.ALL_TEAMS.find { it.id == teamBId }?.name ?: "班组$teamBId"

    val commonDates = (0 until daysToAnalyze).mapNotNull { offset ->
        val date = today.plusDays(offset.toLong())
        val shiftA = getShiftTypeForDate(date, offsetA, customCycle, referenceDate)
        val shiftB = getShiftTypeForDate(date, offsetB, customCycle, referenceDate)
        val isRestA = shiftA == ShiftType.REST || shiftA == ShiftType.STUDY
        val isRestB = shiftB == ShiftType.REST || shiftB == ShiftType.STUDY
        if (isRestA && isRestB) date else null
    }

    val next = commonDates.firstOrNull()
    val daysUntil = next?.let { ChronoUnit.DAYS.between(today, it).toInt() }
    val todayEpoch = today.toEpochDay()
    val count30 = commonDates.count { it.toEpochDay() - todayEpoch < 30 }
    val count60 = commonDates.count { it.toEpochDay() - todayEpoch < 60 }

    return CommonRestResult(
        teamAName = teamAName,
        teamBName = teamBName,
        nextCommonRestDate = next,
        daysUntilNext = daysUntil,
        commonRestDates = commonDates,
        totalCount = commonDates.size,
        countIn30Days = count30,
        countIn60Days = count60
    )
}
