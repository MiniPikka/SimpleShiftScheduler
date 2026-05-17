package com.simpleshift.scheduler.domain.model

import androidx.compose.runtime.Immutable
import java.time.YearMonth

@Immutable
data class SalaryBreakdown(
    val month: YearMonth,
    val shiftCounts: Map<ShiftType, Int>,
    val shiftPremiumTotal: Double
)
