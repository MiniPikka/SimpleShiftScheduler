package com.simpleshift.scheduler.domain.model

import androidx.compose.runtime.Immutable

@Immutable
data class Team(val id: Int) {
    companion object {
        const val TOTAL_TEAMS = 6
        val ALL_TEAMS: List<Team> = (1..TOTAL_TEAMS).map { Team(id = it) }
    }
}
