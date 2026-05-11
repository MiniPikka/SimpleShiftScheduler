package com.simpleshift.scheduler.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.CalendarEventIds
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftType
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "shift_settings")

class SettingsRepository(private val context: Context) {

    companion object {
        private val KEY_CYCLE_LENGTH = intPreferencesKey("cycle_length")
        private val KEY_SHIFT_CYCLE = stringPreferencesKey("shift_cycle")
        private val KEY_DEFAULT_TEAM = intPreferencesKey("default_team")
        private val KEY_CALENDAR_EVENT_IDS = stringPreferencesKey("calendar_event_ids")

        private val KEY_ALARM_TIME: Map<ShiftType, Preferences.Key<String>> =
            ShiftType.entries.associateWith { type ->
                stringPreferencesKey("alarm_time_${type.name.lowercase()}")
            }

        private const val DELIMITER = ","
        private const val ALARM_TIME_SEPARATOR = ":"
        private const val EVENT_ID_SEPARATOR = "="
        private const val EVENT_ENTRY_SEPARATOR = ","

        fun serializeShiftCycle(cycle: List<ShiftType>): String {
            return cycle.joinToString(DELIMITER) { it.name }
        }

        fun deserializeShiftCycle(serialized: String): List<ShiftType>? {
            if (serialized.isBlank()) return null
            return try {
                serialized.split(DELIMITER).map { ShiftType.valueOf(it.trim()) }
            } catch (e: Exception) {
                null
            }
        }
    }

    val settingsFlow: Flow<RuntimeShiftSettings> = context.dataStore.data.map { prefs ->
        val cycleLength = prefs[KEY_CYCLE_LENGTH]
        val shiftCycleStr = prefs[KEY_SHIFT_CYCLE]
        val defaultTeam = prefs[KEY_DEFAULT_TEAM]

        if (cycleLength != null && shiftCycleStr != null) {
            val cycle = deserializeShiftCycle(shiftCycleStr)
            if (cycle != null && cycle.size == cycleLength) {
                RuntimeShiftSettings(
                    cycleLength = cycleLength,
                    shiftCycle = cycle,
                    defaultTeamId = defaultTeam ?: 1
                )
            } else {
                RuntimeShiftSettings()
            }
        } else {
            RuntimeShiftSettings()
        }
    }

    suspend fun saveSettings(settings: RuntimeShiftSettings) {
        context.dataStore.edit { prefs ->
            prefs[KEY_CYCLE_LENGTH] = settings.cycleLength
            prefs[KEY_SHIFT_CYCLE] = serializeShiftCycle(settings.shiftCycle)
            prefs[KEY_DEFAULT_TEAM] = settings.defaultTeamId
        }
    }

    val alarmSettingsFlow: Flow<AlarmSettings> = context.dataStore.data.map { prefs ->
        val alarms = ShiftType.entries.associateWith { type ->
            val key = KEY_ALARM_TIME[type]!!
            val raw = prefs[key]
            if (raw.isNullOrEmpty()) {
                null
            } else {
                parseAlarmTime(raw)
            }
        }
        AlarmSettings(alarms)
    }

    suspend fun saveAlarmSettings(settings: AlarmSettings) {
        context.dataStore.edit { prefs ->
            ShiftType.entries.forEach { type ->
                val time = settings.alarms[type]
                prefs[KEY_ALARM_TIME[type]!!] = if (time != null) {
                    "${time.hour}$ALARM_TIME_SEPARATOR${time.minute}"
                } else {
                    ""
                }
            }
        }
    }

    val calendarEventIdsFlow: Flow<CalendarEventIds> = context.dataStore.data.map { prefs ->
        val raw = prefs[KEY_CALENDAR_EVENT_IDS] ?: ""
        if (raw.isBlank()) {
            CalendarEventIds()
        } else {
            parseCalendarEventIds(raw)
        }
    }

    suspend fun saveCalendarEventIds(ids: CalendarEventIds) {
        val serialized = ids.eventIds.entries.joinToString(EVENT_ENTRY_SEPARATOR) { (key, value) ->
            "$key$EVENT_ID_SEPARATOR$value"
        }
        val current = context.dataStore.data.first()[KEY_CALENDAR_EVENT_IDS] ?: ""
        if (serialized == current) return
        context.dataStore.edit { prefs ->
            prefs[KEY_CALENDAR_EVENT_IDS] = serialized
        }
    }

    private fun parseAlarmTime(raw: String): AlarmTime? {
        val parts = raw.split(ALARM_TIME_SEPARATOR)
        if (parts.size != 2) return null
        val h = parts[0].toIntOrNull() ?: return null
        val m = parts[1].toIntOrNull() ?: return null
        if (h !in 0..23 || m !in 0..59) return null
        return AlarmTime(h, m)
    }

    private fun parseCalendarEventIds(raw: String): CalendarEventIds {
        val map = mutableMapOf<String, Long>()
        val entries = raw.split(EVENT_ENTRY_SEPARATOR)
        for (entry in entries) {
            val parts = entry.split(EVENT_ID_SEPARATOR)
            if (parts.size == 2) {
                val id = parts[1].toLongOrNull()
                if (id != null && id > 0) {
                    map[parts[0]] = id
                }
            }
        }
        return CalendarEventIds(map)
    }
}
