package com.simpleshift.scheduler.domain.model

import java.time.LocalDate

data class ShiftInfo(
    val date: LocalDate,
    val dayOfCycle: Int,
    val shiftType: ShiftType
)
