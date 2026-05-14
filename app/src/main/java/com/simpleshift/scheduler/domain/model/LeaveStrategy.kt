package com.simpleshift.scheduler.domain.model

import java.time.LocalDate

data class LeaveStrategy(
    val leaveDays: Int,
    val totalBreakDays: Int,
    val leaveDates: List<LocalDate>,
    val breakStart: LocalDate,
    val breakEnd: LocalDate,
    val holidayOverlap: Int,
    val weekendOverlap: Int,
    val overlappingHolidayNames: List<String>,
    val efficiency: Float,
    val score: Float
)
