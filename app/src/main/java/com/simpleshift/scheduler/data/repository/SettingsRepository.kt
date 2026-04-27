package com.simpleshift.scheduler.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftType
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "shift_settings")

class SettingsRepository(private val context: Context) {

    companion object {
        private val KEY_CYCLE_LENGTH = intPreferencesKey("cycle_length")
        private val KEY_SHIFT_CYCLE = stringPreferencesKey("shift_cycle")
        private val KEY_DEFAULT_TEAM = intPreferencesKey("default_team")

        private const val DELIMITER = ","

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
}
