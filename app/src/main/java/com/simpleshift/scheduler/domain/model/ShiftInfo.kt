package com.simpleshift.scheduler.domain.model

import androidx.compose.runtime.Immutable
import java.time.LocalDate

@Immutable
data class ShiftInfo(
    val date: LocalDate,
    val dayOfCycle: Int,
    val shiftType: ShiftType
)
