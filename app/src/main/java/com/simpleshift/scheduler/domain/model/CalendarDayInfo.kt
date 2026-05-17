package com.simpleshift.scheduler.domain.model

import androidx.compose.runtime.Immutable
import java.time.LocalDate

@Immutable
data class CalendarDayInfo(
    val date: LocalDate,
    val shiftType: ShiftType,
    val isCurrentMonth: Boolean
)
