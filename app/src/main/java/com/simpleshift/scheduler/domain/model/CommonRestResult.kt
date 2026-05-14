package com.simpleshift.scheduler.domain.model

import java.time.LocalDate

data class CommonRestResult(
    val teamAName: String,
    val teamBName: String,
    val nextCommonRestDate: LocalDate?,
    val daysUntilNext: Int?,
    val commonRestDates: List<LocalDate>,
    val totalCount: Int,
    val countIn30Days: Int,
    val countIn60Days: Int
)
