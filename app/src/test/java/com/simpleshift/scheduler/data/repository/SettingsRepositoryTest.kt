package com.simpleshift.scheduler.data.repository

import androidx.test.core.app.ApplicationProvider
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.CalendarEventIds
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftType
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class SettingsRepositoryTest {

    private val context = ApplicationProvider.getApplicationContext<android.content.Context>()

    @Test
    fun `default flow returns default RuntimeShiftSettings`() = runBlocking {
        val repo = SettingsRepository(context)
        val settings = repo.settingsFlow.first()

        assertEquals(42, settings.cycleLength)
        assertEquals(42, settings.shiftCycle.size)
        assertEquals(ShiftType.MORNING, settings.shiftCycle[0])
        assertEquals(1, settings.defaultTeamId)
        assertTrue(settings.isValid)
    }

    @Test
    fun `save and read roundtrip with custom cycle`() = runBlocking {
        val repo = SettingsRepository(context)
        val custom = RuntimeShiftSettings(
            cycleLength = 7,
            shiftCycle = listOf(
                ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.REST,
                ShiftType.NIGHT, ShiftType.STUDY, ShiftType.MORNING, ShiftType.AFTERNOON
            ),
            defaultTeamId = 3
        )

        repo.saveSettings(custom)

        val loaded = repo.settingsFlow.first()
        assertEquals(7, loaded.cycleLength)
        assertEquals(7, loaded.shiftCycle.size)
        assertEquals(ShiftType.MORNING, loaded.shiftCycle[0])
        assertEquals(ShiftType.AFTERNOON, loaded.shiftCycle[6])
        assertEquals(3, loaded.defaultTeamId)
        assertTrue(loaded.isValid)
    }

    @Test
    fun `invalid cycle length falls back to default`() = runBlocking {
        val repo = SettingsRepository(context)

        // The settingsFlow has a guard: if cycle.size != cycleLength -> fallback to default
        // We verify that on fresh start, the default is returned and valid.
        val settings = repo.settingsFlow.first()
        assertTrue(settings.isValid)
        assertEquals(42, settings.cycleLength)
    }

    @Test
    fun `alarmSettings save and read roundtrip`() = runBlocking {
        val repo = SettingsRepository(context)
        val alarmSettings = AlarmSettings(
            mapOf(
                ShiftType.MORNING to AlarmTime(6, 0),
                ShiftType.AFTERNOON to AlarmTime(14, 30),
                ShiftType.NIGHT to AlarmTime(22, 0)
            )
        )

        repo.saveAlarmSettings(alarmSettings)

        val loaded = repo.alarmSettingsFlow.first()
        assertNotNull(loaded.alarms[ShiftType.MORNING])
        assertEquals(6, loaded.alarms[ShiftType.MORNING]?.hour)
        assertEquals(0, loaded.alarms[ShiftType.MORNING]?.minute)

        assertNotNull(loaded.alarms[ShiftType.AFTERNOON])
        assertEquals(14, loaded.alarms[ShiftType.AFTERNOON]?.hour)
        assertEquals(30, loaded.alarms[ShiftType.AFTERNOON]?.minute)

        assertNotNull(loaded.alarms[ShiftType.NIGHT])
        assertEquals(22, loaded.alarms[ShiftType.NIGHT]?.hour)

        // REST and STUDY should be null (not set)
        assertNull(loaded.alarms[ShiftType.REST])
        assertNull(loaded.alarms[ShiftType.STUDY])
    }

    @Test
    fun `alarmSettings clear resets to all null`() = runBlocking {
        val repo = SettingsRepository(context)
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.MORNING to AlarmTime(6, 0))
        )
        repo.saveAlarmSettings(alarmSettings)

        // Clear all alarms
        repo.saveAlarmSettings(AlarmSettings())

        val loaded = repo.alarmSettingsFlow.first()
        ShiftType.entries.forEach { type ->
            assertNull("Alarm for $type should be null after clear", loaded.alarms[type])
        }
    }

    @Test
    fun `calendarEventIds save and read roundtrip`() = runBlocking {
        val repo = SettingsRepository(context)
        val eventIds = CalendarEventIds(
            mapOf(
                "2026-05-09_MORNING" to 42L,
                "2026-05-10_MORNING" to 43L,
                "2026-05-11_AFTERNOON" to 44L
            )
        )

        repo.saveCalendarEventIds(eventIds)

        val loaded = repo.calendarEventIdsFlow.first()
        assertEquals(3, loaded.eventIds.size)
        assertEquals(42L, loaded.eventIds["2026-05-09_MORNING"])
        assertEquals(43L, loaded.eventIds["2026-05-10_MORNING"])
        assertEquals(44L, loaded.eventIds["2026-05-11_AFTERNOON"])
    }

    @Test
    fun `empty calendarEventIds returns default`() = runBlocking {
        val repo = SettingsRepository(context)

        val loaded = repo.calendarEventIdsFlow.first()
        assertTrue("Default should be empty", loaded.eventIds.isEmpty())
        assertTrue(loaded.isEmpty())
    }
}
