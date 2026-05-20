package com.simpleshift.scheduler.domain.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AlarmSettingsTest {

    @Test
    fun `default constructor disables all shift types`() {
        val settings = AlarmSettings()
        ShiftType.entries.forEach { type ->
            assertNull("$type should be disabled by default", settings.alarms[type])
            assertFalse(settings.isEnabled(type))
        }
    }

    @Test
    fun `isAnyEnabled returns false when all disabled`() {
        val settings = AlarmSettings()
        assertFalse(settings.isAnyEnabled())
    }

    @Test
    fun `isAnyEnabled returns true when at least one enabled`() {
        val alarms: Map<ShiftType, AlarmTime?> = ShiftType.entries.associateWith { null } +
                (ShiftType.MORNING to AlarmTime(6, 0))
        val settings = AlarmSettings(alarms)
        assertTrue(settings.isAnyEnabled())
        assertTrue(settings.isEnabled(ShiftType.MORNING))
        assertFalse(settings.isEnabled(ShiftType.AFTERNOON))
    }

    @Test
    fun `all shift types covered in alarms map`() {
        val settings = AlarmSettings()
        assertEquals(ShiftType.entries.size, settings.alarms.size)
        ShiftType.entries.forEach { type ->
            assert(settings.alarms.containsKey(type))
        }
    }

    @Test
    fun `multiple shift types can be enabled`() {
        val alarms = mapOf(
            ShiftType.MORNING to AlarmTime(6, 0),
            ShiftType.AFTERNOON to AlarmTime(14, 0),
            ShiftType.REST to null,
            ShiftType.NIGHT to AlarmTime(22, 0),
            ShiftType.STUDY to null
        )
        val settings = AlarmSettings(alarms)
        assertTrue(settings.isEnabled(ShiftType.MORNING))
        assertTrue(settings.isEnabled(ShiftType.AFTERNOON))
        assertFalse(settings.isEnabled(ShiftType.REST))
        assertTrue(settings.isEnabled(ShiftType.NIGHT))
        assertFalse(settings.isEnabled(ShiftType.STUDY))
    }

}
