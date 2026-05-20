package com.simpleshift.scheduler.domain.model

import androidx.compose.runtime.Immutable

@Immutable
data class MonthlyStats(
    val morningCount: Int = 0,
    val afternoonCount: Int = 0,
    val restCount: Int = 0,
    val nightCount: Int = 0,
    val studyCount: Int = 0
)
