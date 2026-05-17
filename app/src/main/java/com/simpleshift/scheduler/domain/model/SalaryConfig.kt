package com.simpleshift.scheduler.domain.model

data class SalaryConfig(
    val shiftPremiums: Map<ShiftType, Double> = emptyMap()
)
