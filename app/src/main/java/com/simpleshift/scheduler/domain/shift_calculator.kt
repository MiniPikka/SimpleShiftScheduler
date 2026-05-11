package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftInfo
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import java.time.LocalDate
import java.time.temporal.ChronoUnit

fun calculateDayOffset(
    date: LocalDate,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
): Int = ChronoUnit.DAYS.between(referenceDate, date).toInt()

fun normalizeCycleIndex(offsetDays: Int, cycleLength: Int = ShiftCycleConfig.CYCLE_LENGTH): Int {
    return (offsetDays % cycleLength + cycleLength) % cycleLength
}

fun getShiftTypeForDate(
    date: LocalDate,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null
): ShiftType {
    val cycle = customCycle ?: ShiftCycleConfig.SHIFT_CYCLE
    val offsetDays = calculateDayOffset(date) + teamPhaseOffset
    val cycleIndex = normalizeCycleIndex(offsetDays, cycle.size)
    return cycle[cycleIndex]
}

fun getShiftInfo(
    date: LocalDate,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null
): ShiftInfo {
    val cycle = customCycle ?: ShiftCycleConfig.SHIFT_CYCLE
    val offsetDays = calculateDayOffset(date) + teamPhaseOffset
    val cycleIndex = normalizeCycleIndex(offsetDays, cycle.size)
    return ShiftInfo(
        date = date,
        dayOfCycle = cycleIndex + 1,
        shiftType = cycle[cycleIndex]
    )
}

fun teamPhaseStepFor(customCycle: List<ShiftType>? = null): Int {
    val totalDays = customCycle?.size ?: ShiftCycleConfig.CYCLE_LENGTH
    return totalDays / Team.TOTAL_TEAMS
}
