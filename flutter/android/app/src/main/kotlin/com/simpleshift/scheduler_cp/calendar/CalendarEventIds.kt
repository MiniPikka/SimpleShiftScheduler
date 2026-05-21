package com.simpleshift.scheduler_cp.calendar

/**
 * Tracks calendar event IDs for dedup: key = "yyyy-MM-dd_X" (X = shift type index 0-4).
 * Ported from Android reference CalendarEventIds.kt.
 */
data class CalendarEventIds(
    val eventIds: Map<String, Long> = emptyMap()
) {
    fun isEmpty(): Boolean = eventIds.isEmpty()

    companion object {
        fun eventKey(date: String, shiftIndex: Int): String = "${date}_$shiftIndex"
    }
}
