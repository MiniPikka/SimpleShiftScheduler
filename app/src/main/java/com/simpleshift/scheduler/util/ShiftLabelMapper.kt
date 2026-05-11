package com.simpleshift.scheduler.util

import com.simpleshift.scheduler.domain.model.ShiftType

object ShiftLabelMapper {
    fun toLabel(shiftType: ShiftType): String = when (shiftType) {
        ShiftType.MORNING -> "早"
        ShiftType.AFTERNOON -> "中"
        ShiftType.REST -> "休"
        ShiftType.NIGHT -> "夜"
        ShiftType.STUDY -> "学"
    }
}
