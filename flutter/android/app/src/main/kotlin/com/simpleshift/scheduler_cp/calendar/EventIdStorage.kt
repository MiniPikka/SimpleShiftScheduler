package com.simpleshift.scheduler_cp.calendar

import android.content.Context

/**
 * Persists CalendarEventIds via SharedPreferences.
 * Serialization format: "key1=id1,key2=id2,..." (same as Android reference DataStore format).
 */
object EventIdStorage {
    private const val PREFS_NAME = "calendar_event_ids_prefs"
    private const val KEY_EVENT_IDS = "event_ids"

    fun load(context: Context): CalendarEventIds {
        val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_EVENT_IDS, "") ?: ""
        if (raw.isEmpty()) return CalendarEventIds()

        val map = mutableMapOf<String, Long>()
        raw.split(",").forEach { entry ->
            val parts = entry.split("=")
            if (parts.size == 2) {
                val id = parts[1].toLongOrNull()
                if (id != null && id > 0) {
                    map[parts[0]] = id
                }
            }
        }
        return CalendarEventIds(map)
    }

    fun save(context: Context, ids: CalendarEventIds) {
        val raw = ids.eventIds.entries.joinToString(",") { (key, value) -> "$key=$value" }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_EVENT_IDS, raw)
            .apply()
    }
}
