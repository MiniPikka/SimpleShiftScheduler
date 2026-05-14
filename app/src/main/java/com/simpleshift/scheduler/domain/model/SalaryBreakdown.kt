package com.simpleshift.scheduler.domain.model

import java.time.YearMonth

data class SalaryBreakdown(
    val month: YearMonth,
    val shiftCounts: Map<ShiftType, Int>,
    val shiftPremiumTotal: Int
)
