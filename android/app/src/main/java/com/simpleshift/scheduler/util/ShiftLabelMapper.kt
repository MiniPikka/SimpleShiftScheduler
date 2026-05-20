package com.simpleshift.scheduler.util

import android.content.Context
import com.simpleshift.scheduler.R
import com.simpleshift.scheduler.domain.model.ShiftType

object ShiftLabelMapper {
    fun toLabel(context: Context, shiftType: ShiftType): String {
        val resId = when (shiftType) {
            ShiftType.MORNING -> R.string.shift_label_morning
            ShiftType.AFTERNOON -> R.string.shift_label_afternoon
            ShiftType.REST -> R.string.shift_label_rest
            ShiftType.NIGHT -> R.string.shift_label_night
            ShiftType.STUDY -> R.string.shift_label_study
        }
        return context.getString(resId)
    }

    fun toFullLabel(context: Context, shiftType: ShiftType): String {
        val resId = when (shiftType) {
            ShiftType.MORNING -> R.string.shift_label_morning_full
            ShiftType.AFTERNOON -> R.string.shift_label_afternoon_full
            ShiftType.REST -> R.string.shift_label_rest_full
            ShiftType.NIGHT -> R.string.shift_label_night_full
            ShiftType.STUDY -> R.string.shift_label_study_full
        }
        return context.getString(resId)
    }
}
