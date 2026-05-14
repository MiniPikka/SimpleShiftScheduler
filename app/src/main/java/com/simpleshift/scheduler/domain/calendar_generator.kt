package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.CalendarDayInfo
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.YearMonth

private const val CALENDAR_GRID_DAYS = 42

fun generateMonthCalendarDays(
    yearMonth: YearMonth,
    firstDayOfWeek: DayOfWeek = DayOfWeek.SUNDAY,
    teamPhaseOffset: Int = 0,
    customCycle: List<ShiftType>? = null,
    referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
): List<CalendarDayInfo> {
    val firstDay = yearMonth.atDay(1)
    val leadingDays = ((firstDay.dayOfWeek.value - firstDayOfWeek.value) + 7) % 7
    val gridStartDate: LocalDate = firstDay.minusDays(leadingDays.toLong())

    return (0 until CALENDAR_GRID_DAYS).map { offset ->
        val date = gridStartDate.plusDays(offset.toLong())
        CalendarDayInfo(
            date = date,
            shiftType = getShiftTypeForDate(date, teamPhaseOffset, customCycle, referenceDate),
            isCurrentMonth = date.month == yearMonth.month
        )
    }
}
