package com.simpleshift.scheduler.calendar

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.result.ActivityResultLauncher
import androidx.core.content.ContextCompat
import com.simpleshift.scheduler.data.repository.SettingsRepository
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.CalendarEventIds
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.Team
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

class CalendarSyncManager(
    private val context: Context,
    private val settingsRepository: SettingsRepository,
    private val calendarEventManager: CalendarEventManager,
    private val runtimeSettingsFlow: MutableStateFlow<RuntimeShiftSettings>,
    private val scope: CoroutineScope
) {
    private val syncMutex = Mutex()
    fun hasCalendarPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(
            context, Manifest.permission.WRITE_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.READ_CALENDAR
            ) == PackageManager.PERMISSION_GRANTED
    }

    fun requestPermissionsIfNeeded(launcher: ActivityResultLauncher<Array<String>>) {
        if (!hasCalendarPermissions() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            launcher.launch(
                arrayOf(
                    Manifest.permission.READ_CALENDAR,
                    Manifest.permission.WRITE_CALENDAR
                )
            )
        }
    }

    fun startAutoSync() {
        scope.launch {
            combine(
                settingsRepository.settingsFlow,
                settingsRepository.alarmSettingsFlow,
                settingsRepository.calendarEventIdsFlow
            ) { shiftSettings, alarmSettings, eventIds ->
                Triple(shiftSettings, alarmSettings, eventIds)
            }.collect { (shiftSettings, alarmSettings, eventIds) ->
                if (shiftSettings.isValid && hasCalendarPermissions()) {
                    syncMutex.withLock {
                        syncCalendarEvents(alarmSettings, shiftSettings, eventIds)
                    }
                }
            }
        }
    }

    fun syncFromCurrentState() {
        if (!hasCalendarPermissions()) return
        scope.launch {
            syncMutex.withLock {
                try {
                    val shiftSettings = runtimeSettingsFlow.value
                    val alarmSettings = settingsRepository.alarmSettingsFlow.first()
                    val eventIds = settingsRepository.calendarEventIdsFlow.first()
                    if (shiftSettings.isValid) {
                        syncCalendarEvents(alarmSettings, shiftSettings, eventIds)
                    }
                } catch (_: Exception) {}
            }
        }
    }

    private suspend fun syncCalendarEvents(
        alarmSettings: AlarmSettings,
        shiftSettings: RuntimeShiftSettings,
        eventIds: CalendarEventIds
    ) {
        if (!shiftSettings.isValid) return
        val phaseOffset = (shiftSettings.defaultTeamId - 1) *
            (shiftSettings.shiftCycle.size / Team.TOTAL_TEAMS)
        val newEventIds = calendarEventManager.syncShiftEvents(
            alarmSettings, shiftSettings.shiftCycle, phaseOffset, eventIds
        )
        settingsRepository.saveCalendarEventIds(newEventIds)
    }
}
