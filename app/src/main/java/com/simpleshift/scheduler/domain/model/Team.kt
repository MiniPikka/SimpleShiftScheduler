package com.simpleshift.scheduler.domain.model

import androidx.compose.runtime.Immutable

@Immutable
data class Team(
    val id: Int,
    val name: String
) {
    companion object {
        const val TOTAL_TEAMS = 6
        private val CHINESE_NUMERALS = listOf("一", "二", "三", "四", "五", "六")
        val ALL_TEAMS: List<Team> = (1..TOTAL_TEAMS).map { id ->
            Team(id = id, name = "${CHINESE_NUMERALS[id - 1]}值")
        }
    }
}
