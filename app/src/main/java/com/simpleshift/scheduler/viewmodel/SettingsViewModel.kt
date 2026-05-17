package com.simpleshift.scheduler.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.compose.runtime.Immutable
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

@Immutable
data class SettingsUiState(
    val cycleLength: Int = ShiftCycleConfig.CYCLE_LENGTH,
    val shiftCycle: List<ShiftType> = ShiftCycleConfig.SHIFT_CYCLE,
    val defaultTeamId: Int = 1,
    val availableTeams: List<Team> = Team.ALL_TEAMS,
    val alarmSettings: AlarmSettings = AlarmSettings(),
    val isDirty: Boolean = false,
    val isSaved: Boolean = false
)

class SettingsViewModel(
    application: Application,
    initialSettings: RuntimeShiftSettings = RuntimeShiftSettings(),
    initialAlarmSettings: AlarmSettings = AlarmSettings(),
    private val onSettingsSaved: (RuntimeShiftSettings) -> Unit = {},
    private val onAlarmSettingsChanged: (AlarmSettings) -> Unit = {}
) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(
        SettingsUiState(
            cycleLength = initialSettings.cycleLength,
            shiftCycle = initialSettings.shiftCycle,
            defaultTeamId = initialSettings.defaultTeamId,
            alarmSettings = initialAlarmSettings
        )
    )
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    private var savedSettings = initialSettings

    fun updateCycleLength(newLength: Int) {
        if (newLength < 1 || newLength > 100) return
        val current = _uiState.value
        val newCycle = if (newLength > current.shiftCycle.size) {
            current.shiftCycle + List(newLength - current.shiftCycle.size) { ShiftType.REST }
        } else {
            current.shiftCycle.take(newLength)
        }
        _uiState.value = current.copy(
            cycleLength = newLength,
            shiftCycle = newCycle,
            isDirty = true,
            isSaved = false
        )
    }

    fun setDayShift(dayIndex: Int, shiftType: ShiftType) {
        val current = _uiState.value
        if (dayIndex !in current.shiftCycle.indices) return
        val newCycle = current.shiftCycle.toMutableList().also { it[dayIndex] = shiftType }
        _uiState.value = current.copy(
            shiftCycle = newCycle,
            isDirty = true,
            isSaved = false
        )
    }

    fun selectDefaultTeam(teamId: Int) {
        _uiState.value = _uiState.value.copy(
            defaultTeamId = teamId,
            isDirty = true,
            isSaved = false
        )
    }

    fun updateAlarmTime(shiftType: ShiftType, alarmTime: AlarmTime?) {
        val current = _uiState.value
        val updatedAlarms = current.alarmSettings.alarms + (shiftType to alarmTime)
        val newAlarmSettings = AlarmSettings(updatedAlarms)
        _uiState.value = current.copy(alarmSettings = newAlarmSettings)
        onAlarmSettingsChanged(newAlarmSettings)
    }

    fun save() {
        val current = _uiState.value
        val settings = RuntimeShiftSettings(
            cycleLength = current.cycleLength,
            shiftCycle = current.shiftCycle,
            defaultTeamId = current.defaultTeamId
        )
        savedSettings = settings
        onSettingsSaved(settings)
        _uiState.value = current.copy(isDirty = false, isSaved = true)
    }

    fun cancel() {
        val current = _uiState.value
        _uiState.value = SettingsUiState(
            cycleLength = savedSettings.cycleLength,
            shiftCycle = savedSettings.shiftCycle,
            defaultTeamId = savedSettings.defaultTeamId,
            alarmSettings = current.alarmSettings
        )
    }
}
