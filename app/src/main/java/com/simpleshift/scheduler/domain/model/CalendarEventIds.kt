package com.simpleshift.scheduler.domain.model

import androidx.compose.runtime.Immutable

@Immutable
data class CalendarEventIds(
    val eventIds: Map<String, Long> = emptyMap()
) {

    fun isEmpty(): Boolean = eventIds.isEmpty()

    companion object {
        /**
         * Builds a key for tracking a calendar event: "yyyy-MM-dd_SHIFT_TYPE_NAME"
         * e.g. "2026-05-09_MORNING"
         */
        fun eventKey(date: String, shiftType: ShiftType): String {
            return "${date}_${shiftType.name}"
        }
    }
}
