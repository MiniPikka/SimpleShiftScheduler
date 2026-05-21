package com.simpleshift.scheduler_cp.calendar

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.provider.CalendarContract
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * Writes shift reminders to the system calendar via Calendar Provider.
 *
 * All shift calculation happens in Dart (single source of truth).
 * This class only handles platform-specific Calendar Provider CRUD — no algorithm.
 */
class CalendarEventManager(private val context: Context) {
    private val resolver = context.contentResolver
    private val zoneId = ZoneId.systemDefault()

    // ── Calendar account management ──────────────────────────

    fun getOrCreateLocalCalendar(): Long {
        val existingId = findLocalCalendar()
        if (existingId != -1L) return existingId
        return createLocalCalendar()
    }

    private fun findLocalCalendar(): Long {
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.ACCOUNT_TYPE,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME
        )
        val selection = "${CalendarContract.Calendars.ACCOUNT_TYPE} = ? AND ${CalendarContract.Calendars.ACCOUNT_NAME} = ?"
        val selectionArgs = arrayOf(CalendarContract.ACCOUNT_TYPE_LOCAL, ACCOUNT_NAME)

        resolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection, selection, selectionArgs, null
        )?.use { cursor ->
            if (cursor.moveToFirst())
                return cursor.getLong(cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID))
        }

        val nameSelection = "${CalendarContract.Calendars.CALENDAR_DISPLAY_NAME} = ?"
        resolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection, nameSelection, arrayOf(CALENDAR_DISPLAY_NAME), null
        )?.use { cursor ->
            if (cursor.moveToFirst())
                return cursor.getLong(cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID))
        }
        return -1L
    }

    private fun createLocalCalendar(): Long {
        val values = ContentValues().apply {
            put(CalendarContract.Calendars.NAME, CALENDAR_NAME)
            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, CALENDAR_DISPLAY_NAME)
            put(CalendarContract.Calendars.CALENDAR_COLOR, CALENDAR_COLOR)
            put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
            put(CalendarContract.Calendars.OWNER_ACCOUNT, OWNER_ACCOUNT)
            put(CalendarContract.Calendars.VISIBLE, 1)
            put(CalendarContract.Calendars.SYNC_EVENTS, 0)
            put(CalendarContract.Calendars.ACCOUNT_NAME, ACCOUNT_NAME)
            put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
        }

        try {
            val newUri = resolver.insert(CalendarContract.Calendars.CONTENT_URI, values)
            if (newUri != null) return ContentUris.parseId(newUri)
        } catch (_: Exception) {}

        val syncUri = CalendarContract.Calendars.CONTENT_URI.buildUpon()
            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, ACCOUNT_NAME)
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            .build()

        return try {
            val newUri = resolver.insert(syncUri, values)
            if (newUri != null) ContentUris.parseId(newUri) else -1L
        } catch (_: Exception) {
            -1L
        }
    }

    // ── Sync (accepts pre-computed events from Dart) ──────────

    /**
     * Sync pre-computed shift events to the system calendar.
     *
     * @param events list of maps, each containing:
     *   date_key, shift_index, event_year, event_month, event_day,
     *   trigger_hour, trigger_minute
     * @param existingEventIds tracked event IDs for dedup
     * @return Pair of (created_count, updated_CalendarEventIds)
     */
    fun syncShiftEvents(
        events: List<Map<String, Any>>,
        existingEventIds: CalendarEventIds = CalendarEventIds()
    ): Pair<Int, CalendarEventIds> {
        val calendarId = getOrCreateLocalCalendar()
        if (calendarId == -1L) return Pair(0, existingEventIds)

        // First run — clean up stale events from previous versions
        if (existingEventIds.isEmpty()) {
            deleteAllEventsInCalendar(calendarId)
        }

        val now = System.currentTimeMillis()
        var created = 0
        val expectedKeys = mutableSetOf<String>()
        val newEventIds = existingEventIds.eventIds.toMutableMap()

        for (event in events) {
            val dateKey = event["date_key"] as? String ?: continue
            val shiftIndex = (event["shift_index"] as? Number)?.toInt() ?: continue
            val eventYear = (event["event_year"] as? Number)?.toInt() ?: continue
            val eventMonth = (event["event_month"] as? Number)?.toInt() ?: continue
            val eventDay = (event["event_day"] as? Number)?.toInt() ?: continue
            val triggerHour = (event["trigger_hour"] as? Number)?.toInt() ?: continue
            val triggerMinute = (event["trigger_minute"] as? Number)?.toInt() ?: 0

            val triggerAt = ZonedDateTime.of(
                eventYear, eventMonth, eventDay,
                triggerHour, triggerMinute, 0, 0, zoneId
            ).toInstant().toEpochMilli()

            if (triggerAt <= now) continue

            val key = CalendarEventIds.eventKey(dateKey, shiftIndex)
            expectedKeys.add(key)

            // Tier 1: check tracked IDs
            if (newEventIds.containsKey(key)) continue

            // Tier 2: check system calendar
            val eventDate = LocalDate.of(eventYear, eventMonth, eventDay)
            val existingEventId = findExistingEvent(calendarId, eventDate, shiftIndex)
            if (existingEventId != -1L) {
                newEventIds[key] = existingEventId
                continue
            }

            // Create new event
            val title = shiftLabel(shiftIndex)
            val endMillis = triggerAt + EVENT_DURATION_MS

            val values = ContentValues().apply {
                put(CalendarContract.Events.CALENDAR_ID, calendarId)
                put(CalendarContract.Events.TITLE, title)
                put(CalendarContract.Events.DESCRIPTION, title)
                put(CalendarContract.Events.DTSTART, triggerAt)
                put(CalendarContract.Events.DTEND, endMillis)
                put(CalendarContract.Events.EVENT_TIMEZONE, zoneId.id)
                put(CalendarContract.Events.HAS_ALARM, 1)
                put(CalendarContract.Events.AVAILABILITY, CalendarContract.Events.AVAILABILITY_BUSY)
            }

            try {
                val uri = resolver.insert(CalendarContract.Events.CONTENT_URI, values)
                if (uri != null) {
                    val eventId = ContentUris.parseId(uri)
                    insertReminder(eventId)
                    newEventIds[key] = eventId
                    created++
                }
            } catch (_: Exception) {}
        }

        // Remove stale events (tracked but no longer expected)
        val keysToRemove = newEventIds.keys.filter { it !in expectedKeys }
        for (key in keysToRemove) {
            val eventId = newEventIds[key] ?: continue
            deleteEventById(eventId)
            newEventIds.remove(key)
        }

        return Pair(created, CalendarEventIds(newEventIds))
    }

    // ── Calendar queries ─────────────────────────────────────

    private fun findExistingEvent(
        calendarId: Long,
        date: LocalDate,
        shiftIndex: Int
    ): Long {
        val title = shiftLabel(shiftIndex)
        val dayStart = date.atStartOfDay(zoneId).toInstant().toEpochMilli()
        val dayEnd = date.plusDays(1).atStartOfDay(zoneId).toInstant().toEpochMilli()

        val projection = arrayOf(CalendarContract.Events._ID)
        val selection = "${CalendarContract.Events.CALENDAR_ID} = ?" +
            " AND ${CalendarContract.Events.TITLE} = ?" +
            " AND ${CalendarContract.Events.DTSTART} >= ?" +
            " AND ${CalendarContract.Events.DTSTART} < ?"
        val selectionArgs = arrayOf(
            calendarId.toString(), title,
            dayStart.toString(), dayEnd.toString()
        )

        return try {
            resolver.query(
                CalendarContract.Events.CONTENT_URI,
                projection, selection, selectionArgs, null
            )?.use { cursor ->
                if (cursor.moveToFirst())
                    cursor.getLong(cursor.getColumnIndexOrThrow(CalendarContract.Events._ID))
                else -1L
            } ?: -1L
        } catch (_: Exception) {
            -1L
        }
    }

    // ── Event CRUD helpers ───────────────────────────────────

    private fun insertReminder(eventId: Long) {
        val values = ContentValues().apply {
            put(CalendarContract.Reminders.EVENT_ID, eventId)
            put(CalendarContract.Reminders.MINUTES, 0)
            put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
        }
        try {
            resolver.insert(CalendarContract.Reminders.CONTENT_URI, values)
        } catch (_: Exception) {}
    }

    private fun deleteAllEventsInCalendar(calendarId: Long) {
        val selection = "${CalendarContract.Events.CALENDAR_ID} = ?"
        try {
            resolver.delete(CalendarContract.Events.CONTENT_URI, selection, arrayOf(calendarId.toString()))
        } catch (_: Exception) {}
    }

    private fun deleteEventById(eventId: Long) {
        val deleteUri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId)
        try {
            resolver.delete(deleteUri, null, null)
        } catch (_: Exception) {}
    }

    fun deleteAllEvents() {
        val calendarId = findLocalCalendar()
        if (calendarId == -1L) return
        deleteAllEventsInCalendar(calendarId)
    }

    private fun shiftLabel(index: Int): String = when (index) {
        0 -> "早班提醒"
        1 -> "中班提醒"
        2 -> "休班提醒"
        3 -> "夜班提醒"
        4 -> "学班提醒"
        else -> "班次提醒"
    }

    companion object {
        private const val ACCOUNT_NAME = "SimpleShiftScheduler"
        private const val OWNER_ACCOUNT = "simpleshift.local"
        private const val CALENDAR_NAME = "倒班助手"
        private const val CALENDAR_DISPLAY_NAME = "倒班助手提醒"
        private const val CALENDAR_COLOR = 0xFF4CAF50.toInt()
        private const val EVENT_DURATION_MS = 15 * 60 * 1000L
    }
}
