package com.simpleshift.scheduler.util

import android.content.Context
import com.simpleshift.scheduler.R

object TeamNameMapper {
    fun toName(teamId: Int, context: Context): String {
        val resId = when (teamId) {
            1 -> R.string.team_name_1
            2 -> R.string.team_name_2
            3 -> R.string.team_name_3
            4 -> R.string.team_name_4
            5 -> R.string.team_name_5
            6 -> R.string.team_name_6
            else -> R.string.team_name_1
        }
        return context.getString(resId)
    }
}
