package com.simpleshift.scheduler.domain.model

import java.time.LocalDate

data class CalendarDayInfo(
    val date: LocalDate,
    val shiftType: ShiftType,
    val isCurrentMonth: Boolean
)
