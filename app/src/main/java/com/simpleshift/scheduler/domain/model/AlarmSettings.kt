package com.simpleshift.scheduler.domain.model

data class AlarmSettings(
    val alarms: Map<ShiftType, AlarmTime?> = ShiftType.entries.associateWith { null }
) {
    fun isEnabled(shiftType: ShiftType): Boolean = alarms[shiftType] != null

    fun isAnyEnabled(): Boolean = alarms.values.any { it != null }
}
