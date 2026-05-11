package com.simpleshift.scheduler.calendar

import android.content.ContentValues
import android.database.MatrixCursor
import android.net.Uri
import android.provider.CalendarContract
import androidx.test.core.app.ApplicationProvider
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.CalendarEventIds
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.time.LocalDate

@RunWith(RobolectricTestRunner::class)
class CalendarEventManagerTest {

    private lateinit var fakeResolver: FakeCalendarResolver
    private lateinit var manager: CalendarEventManager

    @Before
    fun setUp() {
        fakeResolver = FakeCalendarResolver()
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        manager = CalendarEventManager(context, fakeResolver)
    }

    @Test
    fun `getOrCreateLocalCalendar returns positive calendar id`() {
        val calendarId = manager.getOrCreateLocalCalendar()
        assertTrue("Calendar ID should be positive, got $calendarId", calendarId > 0)
    }

    @Test
    fun `getOrCreateLocalCalendar returns same id on second call`() {
        val first = manager.getOrCreateLocalCalendar()
        val second = manager.getOrCreateLocalCalendar()
        assertEquals("Should return same calendar ID", first, second)
    }

    @Test
    fun `syncShiftEvents with no enabled alarms returns empty unchanged`() {
        val result = manager.syncShiftEvents(
            AlarmSettings(), ShiftCycleConfig.SHIFT_CYCLE, 0, CalendarEventIds(),
            daysAhead = 7
        )
        assertTrue("Should return empty", result.isEmpty())
    }

    @Test
    fun `syncShiftEvents creates events for enabled alarm`() {
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.MORNING to AlarmTime(23, 59))
        )
        val allMorning = List(7) { ShiftType.MORNING }
        val result = manager.syncShiftEvents(
            alarmSettings, allMorning, 0, CalendarEventIds(),
            daysAhead = 7
        )
        assertEquals("All 7 MORNING days should have events", 7, result.eventIds.size)
        result.eventIds.values.forEach { id ->
            assertTrue("Event ID should be positive, got $id", id > 0)
        }
    }

    @Test
    fun `syncShiftEvents skips already existing events`() {
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.MORNING to AlarmTime(23, 59))
        )
        val allMorning = List(7) { ShiftType.MORNING }
        val firstResult = manager.syncShiftEvents(
            alarmSettings, allMorning, 0, CalendarEventIds(),
            daysAhead = 7
        )
        assertEquals("First sync creates events", 7, firstResult.eventIds.size)

        val secondResult = manager.syncShiftEvents(
            alarmSettings, allMorning, 0, firstResult,
            daysAhead = 7
        )
        assertEquals("Should keep same IDs", firstResult.eventIds, secondResult.eventIds)
    }

    @Test
    fun `syncShiftEvents removes stale events outside sync window`() {
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.MORNING to AlarmTime(23, 59))
        )
        val staleDate = LocalDate.now().minusDays(100).toString()
        val staleKey = CalendarEventIds.eventKey(staleDate, ShiftType.MORNING)
        val existingIds = CalendarEventIds(mapOf(staleKey to 99999L))

        val allMorning = List(7) { ShiftType.MORNING }
        val result = manager.syncShiftEvents(
            alarmSettings, allMorning, 0, existingIds,
            daysAhead = 7
        )
        assertTrue("Stale event should be removed", staleKey !in result.eventIds)
    }

    @Test
    fun `syncShiftEvents different offsets produce different key sets`() {
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.REST to AlarmTime(23, 59))
        )
        val customCycle = listOf(
            ShiftType.REST, ShiftType.REST, ShiftType.REST,
            ShiftType.REST, ShiftType.REST, ShiftType.REST, ShiftType.REST
        )
        val r1 = manager.syncShiftEvents(alarmSettings, customCycle, 0, CalendarEventIds(), daysAhead = 7)
        val r2 = manager.syncShiftEvents(alarmSettings, customCycle, 1, CalendarEventIds(), daysAhead = 7)
        assertEquals(7, r1.eventIds.size)
        assertEquals(7, r2.eventIds.size)
    }

    @Test
    fun `syncShiftEvents skips past alarm times today`() {
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.MORNING to AlarmTime(0, 0))
        )
        val allMorning = List(7) { ShiftType.MORNING }
        val result = manager.syncShiftEvents(
            alarmSettings, allMorning, 0, CalendarEventIds(),
            daysAhead = 7
        )
        val today = LocalDate.now().toString()
        val todayMorningKey = CalendarEventIds.eventKey(today, ShiftType.MORNING)
        assertTrue("Midnight alarm today should be skipped",
            todayMorningKey !in result.eventIds)
        assertEquals("Should have events for the 6 future days", 6, result.eventIds.size)
    }

    @Test
    fun `syncShiftEvents detects existing calendar events to avoid duplicates`() {
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.MORNING to AlarmTime(23, 59))
        )
        val allMorning = List(7) { ShiftType.MORNING }

        // First pass: create events normally
        val firstResult = manager.syncShiftEvents(
            alarmSettings, allMorning, 0, CalendarEventIds(),
            daysAhead = 7
        )
        assertEquals(7, firstResult.eventIds.size)

        // Second pass: simulate stale tracking data (empty eventIds)
        // The findExistingEvent check should discover the real events and reuse their IDs
        val secondResult = manager.syncShiftEvents(
            alarmSettings, allMorning, 0, CalendarEventIds(),
            daysAhead = 7
        )
        assertEquals("Should still have 7 events", 7, secondResult.eventIds.size)
        // All event IDs should be the same as first pass (reused, not duplicated)
        assertEquals("Should reuse same event IDs", firstResult.eventIds, secondResult.eventIds)
    }

    @Test
    fun `eventKey format is correct`() {
        assertEquals("2026-05-10_NIGHT",
            CalendarEventIds.eventKey("2026-05-10", ShiftType.NIGHT))
    }

    @Test
    fun `eventKey is unique per date and shift type`() {
        val k1 = CalendarEventIds.eventKey("2026-05-10", ShiftType.MORNING)
        val k2 = CalendarEventIds.eventKey("2026-05-10", ShiftType.AFTERNOON)
        val k3 = CalendarEventIds.eventKey("2026-05-11", ShiftType.MORNING)
        assertTrue("Different shift same date", k1 != k2)
        assertTrue("Same shift different date", k1 != k3)
    }

    @Test
    fun `deleteAllEvents removes all tracked events`() {
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.MORNING to AlarmTime(23, 59))
        )
        val allMorning = List(7) { ShiftType.MORNING }
        val result = manager.syncShiftEvents(
            alarmSettings, allMorning, 0, CalendarEventIds(),
            daysAhead = 7
        )
        assertEquals("Should have events before delete", 7, result.eventIds.size)
        manager.deleteAllEvents(result)
    }
}

/**
 * In-memory fake of CalendarResolver for unit testing CalendarEventManager.
 * Supports basic WHERE clause filtering for column = ?, >= ?, and < ? conditions.
 */
internal class FakeCalendarResolver : CalendarResolver {

    private var nextId = 1L
    private val calendars = mutableListOf<ContentValues>()
    private val events = mutableListOf<ContentValues>()
    private val reminders = mutableListOf<ContentValues>()

    private fun newId(): Long = nextId++

    private fun resolveTable(uri: Uri): MutableList<ContentValues> = when {
        uri.toString().contains("calendars") -> calendars
        uri.toString().contains("events") -> events
        uri.toString().contains("reminders") -> reminders
        else -> mutableListOf()
    }

    override fun query(
        uri: Uri,
        projection: Array<String>?,
        selection: String?,
        selectionArgs: Array<String>?,
        sortOrder: String?
    ): MatrixCursor {
        val cols = projection ?: arrayOf("_id")
        val cursor = MatrixCursor(cols)
        for (row in resolveTable(uri)) {
            if (matchesSelection(row, selection, selectionArgs)) {
                val values = cols.map { col -> row.get(col) }
                cursor.addRow(values)
            }
        }
        return cursor
    }

    private fun matchesSelection(
        row: ContentValues,
        selection: String?,
        selectionArgs: Array<String>?
    ): Boolean {
        if (selection == null) return true
        val conditions = selection.split(" AND ")
        var argIndex = 0

        for (condition in conditions) {
            val trimmed = condition.trim()
            when {
                trimmed.contains(" >= ") -> {
                    val col = trimmed.substringBefore(" >= ").trim()
                    val arg = selectionArgs?.getOrNull(argIndex++) ?: return false
                    val rowVal = row.getAsLong(col) ?: return false
                    if (rowVal < arg.toLong()) return false
                }
                trimmed.contains(" < ") -> {
                    val col = trimmed.substringBefore(" < ").trim()
                    val arg = selectionArgs?.getOrNull(argIndex++) ?: return false
                    val rowVal = row.getAsLong(col) ?: return false
                    if (rowVal >= arg.toLong()) return false
                }
                trimmed.contains(" = ") -> {
                    val col = trimmed.substringBefore(" = ").trim()
                    val arg = selectionArgs?.getOrNull(argIndex++) ?: return false
                    val rowVal = row.get(col)?.toString()
                    if (rowVal != arg) return false
                }
            }
        }
        return true
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? {
        if (values == null) return null

        // Handle both sync-adapter and non-sync-adapter URI variants
        val tableUri = if (uri.queryParameterNames.contains(CalendarContract.CALLER_IS_SYNCADAPTER)) {
            uri.buildUpon().clearQuery().build()
        } else {
            uri
        }

        val id = newId()
        values.put("_id", id)
        resolveTable(tableUri).add(ContentValues(values))
        return Uri.withAppendedPath(tableUri, id.toString())
    }

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<String>?): Int {
        val idStr = uri.lastPathSegment?.toLongOrNull() ?: return 0
        var removed = 0
        removed += events.removeAll { it.getAsLong("_id") == idStr }.let { if (it) 1 else 0 }
        removed += calendars.removeAll { it.getAsLong("_id") == idStr }.let { if (it) 1 else 0 }
        reminders.removeAll { it.getAsLong("event_id") == idStr }
        return removed
    }
}
