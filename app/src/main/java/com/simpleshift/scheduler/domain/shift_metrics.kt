package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import java.time.LocalDate
import java.time.YearMonth

fun countShiftTypeInMonth(
    yearMonth: YearMonth,
    shiftType: ShiftType,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
): Int {
    val daysInMonth = yearMonth.lengthOfMonth()
    var count = 0
    for (day in 1..daysInMonth) {
        val date = yearMonth.atDay(day)
        if (getShiftTypeForDate(date, teamPhaseOffset, customCycle, referenceDate) == shiftType) {
            count++
        }
    }
    return count
}

fun countWorkDaysInMonth(
    yearMonth: YearMonth,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
): Int {
    val daysInMonth = yearMonth.lengthOfMonth()
    var count = 0
    for (day in 1..daysInMonth) {
        val date = yearMonth.atDay(day)
        val shiftType = getShiftTypeForDate(date, teamPhaseOffset, customCycle, referenceDate)
        if (shiftType != ShiftType.REST && shiftType != ShiftType.STUDY) {
            count++
        }
    }
    return count
}

fun consecutiveWorkDays(
    today: LocalDate,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
): Int {
    var count = 0
    var date = today
    while (true) {
        val shiftType = getShiftTypeForDate(date, teamPhaseOffset, customCycle, referenceDate)
        if (shiftType == ShiftType.REST || shiftType == ShiftType.STUDY) break
        count++
        date = date.minusDays(1)
    }
    return count
}

fun daysUntilNextRest(
    today: LocalDate,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
): Int {
    var days = 0
    var date = today.plusDays(1)
    // Safety limit to prevent infinite loop
    val maxSearch = (customCycle?.size ?: 42) + 1
    while (days < maxSearch) {
        val shiftType = getShiftTypeForDate(date, teamPhaseOffset, customCycle, referenceDate)
        if (shiftType == ShiftType.REST) return days
        days++
        date = date.plusDays(1)
    }
    return 0
}
