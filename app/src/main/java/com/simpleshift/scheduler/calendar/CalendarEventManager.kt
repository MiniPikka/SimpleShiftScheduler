package com.simpleshift.scheduler.calendar

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.provider.CalendarContract
import com.simpleshift.scheduler.domain.getShiftTypeForDate
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.CalendarEventIds
import com.simpleshift.scheduler.domain.model.ShiftType
import java.time.LocalDate
import java.time.ZoneId

class CalendarEventManager(private val context: Context) {

    private val contentResolver = context.contentResolver
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
            CalendarContract.Calendars.ACCOUNT_NAME
        )
        val selection = "${CalendarContract.Calendars.ACCOUNT_TYPE} = ?"
        val selectionArgs = arrayOf(CalendarContract.ACCOUNT_TYPE_LOCAL)

        contentResolver.query(
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

        return -1L
    }

    private fun createLocalCalendar(): Long {
        val uri = CalendarContract.Calendars.CONTENT_URI.buildUpon()
            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, ACCOUNT_NAME)
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            .build()

        val values = ContentValues().apply {
            put(CalendarContract.Calendars.NAME, CALENDAR_NAME)
            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, CALENDAR_DISPLAY_NAME)
            put(CalendarContract.Calendars.CALENDAR_COLOR, CALENDAR_COLOR)
            put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
            put(CalendarContract.Calendars.OWNER_ACCOUNT, OWNER_ACCOUNT)
            put(CalendarContract.Calendars.VISIBLE, 1)
            put(CalendarContract.Calendars.SYNC_EVENTS, 0)
        }

        return try {
            val newUri = contentResolver.insert(uri, values)
            if (newUri != null) {
                ContentUris.parseId(newUri)
            } else {
                findFallbackCalendar()
            }
        } catch (_: Exception) {
            findFallbackCalendar()
        }
    }

    private fun findFallbackCalendar(): Long {
        val projection = arrayOf(CalendarContract.Calendars._ID)
        contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID))
            }
        }
        return -1L
    }

    /**
     * Synchronize calendar events for the next 7 days based on current alarm settings.
     * Returns updated CalendarEventIds to persist.
     */
    fun syncNextSevenDays(
        alarmSettings: AlarmSettings,
        shiftCycle: List<ShiftType>,
        teamPhaseOffset: Int,
        existingEventIds: CalendarEventIds
    ): CalendarEventIds {
        val calendarId = getOrCreateLocalCalendar()
        if (calendarId == -1L) return existingEventIds

        val today = LocalDate.now()
        val now = System.currentTimeMillis()

        val expectedKeys = mutableSetOf<String>()
        val newEventIds = existingEventIds.eventIds.toMutableMap()

        for (dayOffset in 0..6) {
            val date = today.plusDays(dayOffset.toLong())
            val shiftType = getShiftTypeForDate(date, teamPhaseOffset, shiftCycle)
            val alarmTime = alarmSettings.alarms[shiftType] ?: continue

            val triggerAtMillis = alarmTime.toEpochMillis(date)
            if (triggerAtMillis <= now) continue

            val key = CalendarEventIds.eventKey(date.toString(), shiftType)
            expectedKeys.add(key)

            // Skip if we already have a valid event for this key
            if (newEventIds.containsKey(key)) continue

            val eventId = insertEvent(calendarId, date, shiftType, alarmTime)
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

    private fun insertEvent(
        calendarId: Long,
        date: LocalDate,
        shiftType: ShiftType,
        alarmTime: AlarmTime
    ): Long {
        val startMillis = alarmTime.toEpochMillis(date)
        val endMillis = startMillis + EVENT_DURATION_MS

        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId)
            put(CalendarContract.Events.TITLE, "${shiftTypeLabel(shiftType)}班提醒")
            put(CalendarContract.Events.DESCRIPTION, "${shiftTypeLabel(shiftType)}班 - 倒班助手")
            put(CalendarContract.Events.DTSTART, startMillis)
            put(CalendarContract.Events.DTEND, endMillis)
            put(CalendarContract.Events.EVENT_TIMEZONE, zoneId.id)
            put(CalendarContract.Events.HAS_ALARM, 1)
            put(CalendarContract.Events.AVAILABILITY, CalendarContract.Events.AVAILABILITY_BUSY)
        }

        return try {
            val uri = contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
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
            contentResolver.insert(CalendarContract.Reminders.CONTENT_URI, values)
        } catch (_: Exception) {
            // Best-effort
        }
    }

    private fun deleteEvent(eventId: Long) {
        val deleteUri = ContentUris.withAppendedId(
            CalendarContract.Events.CONTENT_URI, eventId
        )
        try {
            contentResolver.delete(deleteUri, null, null)
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

    private fun shiftTypeLabel(shiftType: ShiftType): String {
        return when (shiftType) {
            ShiftType.MORNING -> "早"
            ShiftType.AFTERNOON -> "中"
            ShiftType.REST -> "休"
            ShiftType.NIGHT -> "夜"
            ShiftType.STUDY -> "学"
        }
    }

    companion object {
        private const val ACCOUNT_NAME = "SimpleShiftScheduler"
        private const val OWNER_ACCOUNT = "simpleshift.local"
        private const val CALENDAR_NAME = "倒班助手"
        private const val CALENDAR_DISPLAY_NAME = "倒班助手提醒"
        private const val CALENDAR_COLOR = 0xFF4CAF50.toInt()
        private const val EVENT_DURATION_MS = 15 * 60 * 1000L // 15 minutes
    }
}
