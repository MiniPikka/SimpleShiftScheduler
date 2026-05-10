package com.simpleshift.scheduler.viewmodel

import androidx.test.core.app.ApplicationProvider
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class SettingsViewModelTest {

    @Test
    fun `init emits default settings from initial settings`() {
        val settings = RuntimeShiftSettings(
            cycleLength = 7,
            shiftCycle = listOf(ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.REST,
                ShiftType.NIGHT, ShiftType.STUDY, ShiftType.MORNING, ShiftType.AFTERNOON),
            defaultTeamId = 2
        )
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = settings
        )

        val uiState = viewModel.uiState.value
        assertEquals(7, uiState.cycleLength)
        assertEquals(7, uiState.shiftCycle.size)
        assertEquals(ShiftType.MORNING, uiState.shiftCycle[0])
        assertEquals(2, uiState.defaultTeamId)
        assertFalse(uiState.isDirty)
        assertFalse(uiState.isSaved)
    }

    @Test
    fun `updateCycleLength shrinks cycle correctly`() {
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings()
        )

        viewModel.updateCycleLength(3)
        val uiState = viewModel.uiState.value
        assertEquals(3, uiState.cycleLength)
        assertEquals(3, uiState.shiftCycle.size)
        assertTrue(uiState.isDirty)
    }

    @Test
    fun `updateCycleLength expands cycle with REST padding`() {
        val settings = RuntimeShiftSettings(
            cycleLength = 3,
            shiftCycle = listOf(ShiftType.MORNING, ShiftType.MORNING, ShiftType.AFTERNOON)
        )
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = settings
        )

        viewModel.updateCycleLength(5)
        val uiState = viewModel.uiState.value
        assertEquals(5, uiState.cycleLength)
        assertEquals(5, uiState.shiftCycle.size)
        assertEquals(ShiftType.MORNING, uiState.shiftCycle[0])
        assertEquals(ShiftType.MORNING, uiState.shiftCycle[1])
        assertEquals(ShiftType.AFTERNOON, uiState.shiftCycle[2])
        assertEquals(ShiftType.REST, uiState.shiftCycle[3])
        assertEquals(ShiftType.REST, uiState.shiftCycle[4])
    }

    @Test
    fun `setDayShift updates correct position`() {
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings()
        )

        viewModel.setDayShift(0, ShiftType.NIGHT)
        val uiState = viewModel.uiState.value
        assertEquals(ShiftType.NIGHT, uiState.shiftCycle[0])
        assertTrue(uiState.isDirty)
    }

    @Test
    fun `setDayShift ignores out of bounds index`() {
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings()
        )

        val before = viewModel.uiState.value
        viewModel.setDayShift(999, ShiftType.NIGHT)
        val after = viewModel.uiState.value
        assertEquals(before.shiftCycle, after.shiftCycle)
        assertFalse(after.isDirty)
    }

    @Test
    fun `selectDefaultTeam updates team and marks dirty`() {
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings()
        )

        viewModel.selectDefaultTeam(3)
        val uiState = viewModel.uiState.value
        assertEquals(3, uiState.defaultTeamId)
        assertTrue(uiState.isDirty)
    }

    @Test
    fun `save calls onSettingsSaved and marks saved`() {
        var savedSettings: RuntimeShiftSettings? = null
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings(),
            onSettingsSaved = { savedSettings = it }
        )

        viewModel.updateCycleLength(10)
        viewModel.save()

        val uiState = viewModel.uiState.value
        assertFalse(uiState.isDirty)
        assertTrue(uiState.isSaved)
        assertEquals(10, savedSettings?.cycleLength)
    }

    @Test
    fun `cancel restores original settings`() {
        val originalSettings = RuntimeShiftSettings(cycleLength = 10,
            shiftCycle = List(10) { ShiftType.REST })
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = originalSettings
        )

        viewModel.updateCycleLength(5)
        viewModel.cancel()

        val uiState = viewModel.uiState.value
        assertEquals(10, uiState.cycleLength)
        assertEquals(10, uiState.shiftCycle.size)
        assertFalse(uiState.isDirty)
    }

    @Test
    fun `updateCycleLength with invalid input is ignored`() {
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings()
        )

        val before = viewModel.uiState.value
        viewModel.updateCycleLength(0)
        assertEquals(before.cycleLength, viewModel.uiState.value.cycleLength)

        viewModel.updateCycleLength(101)
        assertEquals(before.cycleLength, viewModel.uiState.value.cycleLength)
    }

    @Test
    fun `init emits default alarm settings from initial alarm settings`() {
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.MORNING to AlarmTime(6, 0))
        )
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings(),
            initialAlarmSettings = alarmSettings
        )

        val uiState = viewModel.uiState.value
        assertNotNull(uiState.alarmSettings.alarms[ShiftType.MORNING])
        assertEquals(6, uiState.alarmSettings.alarms[ShiftType.MORNING]?.hour)
        assertNull(uiState.alarmSettings.alarms[ShiftType.AFTERNOON])
    }

    @Test
    fun `updateAlarmTime sets alarm and triggers callback`() {
        var changedSettings: AlarmSettings? = null
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings(),
            onAlarmSettingsChanged = { changedSettings = it }
        )

        viewModel.updateAlarmTime(ShiftType.MORNING, AlarmTime(7, 30))

        val uiState = viewModel.uiState.value
        assertEquals(7, uiState.alarmSettings.alarms[ShiftType.MORNING]?.hour)
        assertEquals(30, uiState.alarmSettings.alarms[ShiftType.MORNING]?.minute)
        assertNotNull(changedSettings)
        assertEquals(7, changedSettings?.alarms?.get(ShiftType.MORNING)?.hour)
    }

    @Test
    fun `updateAlarmTime with null disables alarm`() {
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.MORNING to AlarmTime(6, 0))
        )
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings(),
            initialAlarmSettings = alarmSettings
        )

        viewModel.updateAlarmTime(ShiftType.MORNING, null)

        val uiState = viewModel.uiState.value
        assertNull(uiState.alarmSettings.alarms[ShiftType.MORNING])
    }

    @Test
    fun `cancel does not reset alarm settings`() {
        val alarmSettings = AlarmSettings(
            mapOf(ShiftType.MORNING to AlarmTime(6, 0))
        )
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings(),
            initialAlarmSettings = alarmSettings
        )

        viewModel.updateAlarmTime(ShiftType.AFTERNOON, AlarmTime(14, 0))
        viewModel.updateCycleLength(10)
        viewModel.cancel()

        // Shift cycle settings reverted
        val uiState = viewModel.uiState.value
        assertEquals(42, uiState.cycleLength)

        // Alarm settings preserved (not reverted by cancel)
        assertNotNull(uiState.alarmSettings.alarms[ShiftType.MORNING])
        assertNotNull(uiState.alarmSettings.alarms[ShiftType.AFTERNOON])
    }

    @Test
    fun `alarm change does not mark shift cycle as dirty`() {
        val viewModel = SettingsViewModel(
            application = ApplicationProvider.getApplicationContext(),
            initialSettings = RuntimeShiftSettings()
        )

        viewModel.updateAlarmTime(ShiftType.MORNING, AlarmTime(6, 0))

        val uiState = viewModel.uiState.value
        assertFalse("Alarm changes should not mark shift cycle as dirty", uiState.isDirty)
    }
}
