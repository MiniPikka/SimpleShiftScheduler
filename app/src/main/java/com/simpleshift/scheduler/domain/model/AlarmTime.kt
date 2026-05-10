package com.simpleshift.scheduler.domain.model

import java.time.LocalDate
import java.time.ZoneId

data class AlarmTime(
    val hour: Int,
    val minute: Int
) {
    init {
        require(hour in 0..23) { "hour must be 0..23, was $hour" }
        require(minute in 0..59) { "minute must be 0..59, was $minute" }
    }

    fun toEpochMillis(date: LocalDate): Long {
        return date
            .atTime(hour, minute)
            .atZone(ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli()
    }
}
