package com.simpleshift.scheduler.domain.model

data class Team(
    val id: Int,
    val name: String
) {
    companion object {
        const val TOTAL_TEAMS = 6
        val ALL_TEAMS: List<Team> = (1..TOTAL_TEAMS).map { id ->
            Team(id = id, name = "班组$id")
        }
    }
}
