package com.simpleshift.scheduler.domain.model

data class RuntimeShiftSettings(
    val cycleLength: Int = ShiftCycleConfig.CYCLE_LENGTH,
    val shiftCycle: List<ShiftType> = ShiftCycleConfig.SHIFT_CYCLE,
    val defaultTeamId: Int = 1
) {
    val isValid: Boolean
        get() = cycleLength in 1..100 && shiftCycle.size == cycleLength
                && shiftCycle.all { it in ShiftType.entries }
                && defaultTeamId in 1..Team.TOTAL_TEAMS
}
