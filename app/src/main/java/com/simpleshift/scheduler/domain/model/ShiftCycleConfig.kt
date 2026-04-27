package com.simpleshift.scheduler.domain.model

import java.time.LocalDate

object ShiftCycleConfig {
    const val CYCLE_LENGTH: Int = 42
    val REFERENCE_DATE: LocalDate = LocalDate.of(2025, 12, 15)

    val SHIFT_CYCLE: List<ShiftType> = listOf(
        ShiftType.MORNING,
        ShiftType.MORNING,
        ShiftType.AFTERNOON,
        ShiftType.AFTERNOON,
        ShiftType.REST,
        ShiftType.NIGHT,
        ShiftType.NIGHT,
        ShiftType.REST,
        ShiftType.REST,
        ShiftType.MORNING,
        ShiftType.MORNING,
        ShiftType.AFTERNOON,
        ShiftType.AFTERNOON,
        ShiftType.REST,
        ShiftType.NIGHT,
        ShiftType.REST,
        ShiftType.REST,
        ShiftType.REST,
        ShiftType.MORNING,
        ShiftType.MORNING,
        ShiftType.AFTERNOON,
        ShiftType.REST,
        ShiftType.NIGHT,
        ShiftType.NIGHT,
        ShiftType.REST,
        ShiftType.REST,
        ShiftType.REST,
        ShiftType.MORNING,
        ShiftType.AFTERNOON,
        ShiftType.AFTERNOON,
        ShiftType.REST,
        ShiftType.NIGHT,
        ShiftType.NIGHT,
        ShiftType.REST,
        ShiftType.REST,
        ShiftType.STUDY,
        ShiftType.STUDY,
        ShiftType.STUDY,
        ShiftType.STUDY,
        ShiftType.STUDY,
        ShiftType.REST,
        ShiftType.REST
    ).also { cycle ->
        require(cycle.size == CYCLE_LENGTH) {
            "Shift cycle length mismatch: expected $CYCLE_LENGTH, got ${cycle.size}"
        }
    }
}
