package com.simpleshift.scheduler.domain.model

import androidx.compose.runtime.Immutable

@Immutable
data class AlarmSettings(
    val alarms: Map<ShiftType, AlarmTime?> = ShiftType.entries.associateWith { null }
) {
    fun isEnabled(shiftType: ShiftType): Boolean = alarms[shiftType] != null

    fun isAnyEnabled(): Boolean = alarms.values.any { it != null }
}
