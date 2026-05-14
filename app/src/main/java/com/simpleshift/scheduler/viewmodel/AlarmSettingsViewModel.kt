package com.simpleshift.scheduler.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.ShiftType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

data class AlarmSettingsUiState(
    val alarmSettings: AlarmSettings = AlarmSettings()
)

class AlarmSettingsViewModel(
    application: Application,
    initialAlarmSettings: AlarmSettings = AlarmSettings(),
    private val onAlarmSettingsChanged: (AlarmSettings) -> Unit = {}
) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(AlarmSettingsUiState(alarmSettings = initialAlarmSettings))
    val uiState: StateFlow<AlarmSettingsUiState> = _uiState.asStateFlow()

    fun updateAlarmTime(shiftType: ShiftType, alarmTime: AlarmTime?) {
        val current = _uiState.value.alarmSettings
        val newAlarms = current.alarms.toMutableMap()
        newAlarms[shiftType] = alarmTime
        val newSettings = AlarmSettings(newAlarms)
        _uiState.value = AlarmSettingsUiState(alarmSettings = newSettings)
        onAlarmSettingsChanged(newSettings)
    }
}
