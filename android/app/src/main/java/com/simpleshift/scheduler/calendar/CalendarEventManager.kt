package com.simpleshift.scheduler.calendar

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.provider.CalendarContract
import android.provider.CalendarContract.Calendars
import com.simpleshift.scheduler.R
import com.simpleshift.scheduler.domain.getShiftTypeForDate
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.CalendarEventIds
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.util.ShiftLabelMapper
import java.time.LocalDate
import java.time.ZoneId

class CalendarEventManager(
    private val context: Context,
    private val resolver: CalendarResolver = ContentCalendarResolver(context.contentResolver)
) {
    private val zoneId = ZoneId.systemDefault()

    /**
     * Find or create a local calendar. Returns the calendar ID, or -1 on failure.
     */
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
        // Match by both ACCOUNT_TYPE and ACCOUNT_NAME to find only our calendar
        val selection = "${CalendarContract.Calendars.ACCOUNT_TYPE} = ? AND ${CalendarContract.Calendars.ACCOUNT_NAME} = ?"
        val selectionArgs = arrayOf(CalendarContract.ACCOUNT_TYPE_LOCAL, ACCOUNT_NAME)

        resolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID))
                if (id > 0) return id
            }
        }

        // Fallback: find by display name (handles calendars created without ACCOUNT_NAME)
        val nameSelection = "${CalendarContract.Calendars.CALENDAR_DISPLAY_NAME} = ?"
        resolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            nameSelection,
            arrayOf(CALENDAR_DISPLAY_NAME),
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID))
                if (id > 0) return id
            }
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

        // Try direct insert first (works on many devices)
        try {
            val newUri = resolver.insert(CalendarContract.Calendars.CONTENT_URI, values)
            if (newUri != null) {
                return ContentUris.parseId(newUri)
            }
        } catch (_: Exception) {}

        // Retry with CALLER_IS_SYNCADAPTER (required on some devices)
        val syncAdapterUri = CalendarContract.Calendars.CONTENT_URI.buildUpon()
            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, ACCOUNT_NAME)
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            .build()

        return try {
            val newUri = resolver.insert(syncAdapterUri, values)
            if (newUri != null) ContentUris.parseId(newUri) else -1L
        } catch (_: Exception) {
            -1L
        }
    }

    /**
     * Synchronize calendar events for the specified number of days ahead.
     * Returns updated CalendarEventIds to persist.
     */
    fun syncShiftEvents(
        alarmSettings: AlarmSettings,
        shiftCycle: List<ShiftType>,
        teamPhaseOffset: Int,
        existingEventIds: CalendarEventIds,
        daysAhead: Int = 365,
        referenceDate: LocalDate = ShiftCycleConfig.REFERENCE_DATE
    ): CalendarEventIds {
        val calendarId = getOrCreateLocalCalendar()
        if (calendarId == -1L) return existingEventIds

        val today = LocalDate.now()
        val now = System.currentTimeMillis()

        val expectedKeys = mutableSetOf<String>()
        val newEventIds = existingEventIds.eventIds.toMutableMap()

        for (dayOffset in 0 until daysAhead) {
            val date = today.plusDays(dayOffset.toLong())
            val shiftType = getShiftTypeForDate(date, teamPhaseOffset, shiftCycle, referenceDate)
            val alarmTime = alarmSettings.alarms[shiftType] ?: continue

            val eventDate = if (shiftType == ShiftType.NIGHT) date.minusDays(1) else date

            val triggerAtMillis = alarmTime.toEpochMillis(eventDate)
            if (triggerAtMillis <= now) continue

            val key = CalendarEventIds.eventKey(date.toString(), shiftType)
            expectedKeys.add(key)

            if (newEventIds.containsKey(key)) continue

            // Check for existing event in system calendar (safety net for stale tracking)
            val existingEventId = findExistingEvent(calendarId, eventDate, shiftType)
            if (existingEventId != -1L) {
                newEventIds[key] = existingEventId
                continue
            }

            val eventId = insertEvent(calendarId, eventDate, shiftType, alarmTime)
            if (eventId != -1L) {
                newEventIds[key] = eventId
            }
        }

        // Remove events that are no longer expected
        val keysToRemove = newEventIds.keys.filter { it !in expectedKeys }
        for (key in keysToRemove) {
            val eventId = newEventIds[key] ?: continue
            deleteEvent(eventId)
            newEventIds.remove(key)
        }

        return CalendarEventIds(newEventIds)
    }

    private fun findExistingEvent(
        calendarId: Long,
        date: LocalDate,
        shiftType: ShiftType
    ): Long {
        val title = when (shiftType) {
            ShiftType.MORNING -> context.getString(R.string.calendar_event_morning)
            ShiftType.AFTERNOON -> context.getString(R.string.calendar_event_afternoon)
            ShiftType.NIGHT -> context.getString(R.string.calendar_event_night)
            ShiftType.STUDY -> context.getString(R.string.calendar_event_study)
            else -> shiftTypeLabel(shiftType)
        }
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

    private fun insertEvent(
        calendarId: Long,
        date: LocalDate,
        shiftType: ShiftType,
        alarmTime: AlarmTime
    ): Long {
        val startMillis = alarmTime.toEpochMillis(date)
        val endMillis = startMillis + EVENT_DURATION_MS

        val title = when (shiftType) {
            ShiftType.MORNING -> context.getString(R.string.calendar_event_morning)
            ShiftType.AFTERNOON -> context.getString(R.string.calendar_event_afternoon)
            ShiftType.NIGHT -> context.getString(R.string.calendar_event_night)
            ShiftType.STUDY -> context.getString(R.string.calendar_event_study)
            else -> shiftTypeLabel(shiftType)
        }

        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId)
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DESCRIPTION, title)
            put(CalendarContract.Events.DTSTART, startMillis)
            put(CalendarContract.Events.DTEND, endMillis)
            put(CalendarContract.Events.EVENT_TIMEZONE, zoneId.id)
            put(CalendarContract.Events.HAS_ALARM, 1)
            put(CalendarContract.Events.AVAILABILITY, CalendarContract.Events.AVAILABILITY_BUSY)
        }

        return try {
            val uri = resolver.insert(CalendarContract.Events.CONTENT_URI, values)
            if (uri != null) {
                val eventId = ContentUris.parseId(uri)
                insertReminder(eventId)
                eventId
            } else {
                -1L
            }
        } catch (_: Exception) {
            -1L
        }
    }

    private fun insertReminder(eventId: Long) {
        val values = ContentValues().apply {
            put(CalendarContract.Reminders.EVENT_ID, eventId)
            put(CalendarContract.Reminders.MINUTES, 0)
            put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
        }
        try {
            resolver.insert(CalendarContract.Reminders.CONTENT_URI, values)
        } catch (_: Exception) {
            // Best-effort
        }
    }

    private fun deleteEvent(eventId: Long) {
        val deleteUri = ContentUris.withAppendedId(
            CalendarContract.Events.CONTENT_URI, eventId
        )
        try {
            resolver.delete(deleteUri, null, null)
        } catch (_: Exception) {
            // Best-effort
        }
    }

    /**
     * Delete all tracked events.
     */
    fun deleteAllEvents(eventIds: CalendarEventIds) {
        for (eventId in eventIds.eventIds.values) {
            deleteEvent(eventId)
        }
    }

    private fun shiftTypeLabel(shiftType: ShiftType): String = ShiftLabelMapper.toLabel(context, shiftType)

    companion object {
        private const val ACCOUNT_NAME = "SimpleShiftScheduler"
        private const val OWNER_ACCOUNT = "simpleshift.local"
        private const val CALENDAR_NAME = "倒班助手"
        private const val CALENDAR_DISPLAY_NAME = "倒班助手提醒"
        private const val CALENDAR_COLOR = 0xFF4CAF50.toInt()
        private const val EVENT_DURATION_MS = 15 * 60 * 1000L // 15 minutes
    }
}
