package com.simpleshift.scheduler.domain.model

import androidx.compose.runtime.Immutable

@Immutable
data class SalaryConfig(
    val shiftPremiums: Map<ShiftType, Double> = emptyMap()
)
