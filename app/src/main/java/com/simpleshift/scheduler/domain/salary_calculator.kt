package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.SalaryBreakdown
import com.simpleshift.scheduler.domain.model.SalaryConfig
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import java.time.LocalDate
import java.time.YearMonth

fun countAllShiftTypesInMonth(
    yearMonth: YearMonth,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
): Map<ShiftType, Int> {
    val counts = mutableMapOf<ShiftType, Int>()
    for (type in ShiftType.entries) {
        counts[type] = 0
    }
    val daysInMonth = yearMonth.lengthOfMonth()
    for (day in 1..daysInMonth) {
        val date = yearMonth.atDay(day)
        val shiftType = getShiftTypeForDate(date, teamPhaseOffset, customCycle, referenceDate)
        counts[shiftType] = counts[shiftType]!! + 1
    }
    return counts
}

fun calculateSalaryBreakdown(
    config: SalaryConfig,
    shiftCounts: Map<ShiftType, Int>,
    yearMonth: YearMonth
): SalaryBreakdown {
    val total = ShiftType.entries.sumOf { type ->
        val premium = config.shiftPremiums[type] ?: 0
        val count = shiftCounts[type] ?: 0
        premium * count
    }
    return SalaryBreakdown(
        month = yearMonth,
        shiftCounts = shiftCounts,
        shiftPremiumTotal = total
    )
}

fun simulateExtraShifts(
    current: SalaryBreakdown,
    extraCount: Int,
    extraShiftType: ShiftType,
    config: SalaryConfig
): SalaryBreakdown {
    val extraAmount = (config.shiftPremiums[extraShiftType] ?: 0) * extraCount
    val newCounts = current.shiftCounts.toMutableMap()
    newCounts[extraShiftType] = (newCounts[extraShiftType] ?: 0) + extraCount
    return SalaryBreakdown(
        month = current.month,
        shiftCounts = newCounts,
        shiftPremiumTotal = current.shiftPremiumTotal + extraAmount
    )
}
