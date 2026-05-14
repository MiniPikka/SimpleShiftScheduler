package com.simpleshift.scheduler.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.ui.common.TeamDropdown
import com.simpleshift.scheduler.ui.home.components.GreetingHeader
import com.simpleshift.scheduler.ui.home.components.MotivationFooter
import com.simpleshift.scheduler.ui.home.components.QuickActionsRow
import com.simpleshift.scheduler.ui.home.components.StatsGrid
import com.simpleshift.scheduler.ui.home.components.TodayShiftCard
import com.simpleshift.scheduler.viewmodel.HomeUiState

@Composable
fun NewHomeScreen(
    uiState: HomeUiState,
    onTeamSelected: (Int) -> Unit,
    onCalendarClick: () -> Unit,
    onSettingsClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        TeamDropdown(
            selectedTeamId = uiState.selectedTeamId,
            availableTeams = uiState.availableTeams,
            onTeamSelected = onTeamSelected
        )
        GreetingHeader(
            teamName = uiState.teamName,
            dateText = uiState.todayDate
        )
        TodayShiftCard(
            shiftLabel = uiState.shiftLabel,
            shiftType = uiState.shiftType,
            dayOfCycle = uiState.dayOfCycle,
            totalDays = uiState.totalDays,
            daysUntilRest = uiState.daysUntilRest
        )
        StatsGrid(
            monthlyWorkDays = uiState.monthlyWorkDays,
            totalDaysInMonth = uiState.totalDaysInMonth,
            consecutiveWorkDays = uiState.consecutiveWorkDays,
            daysUntilRest = uiState.daysUntilRest
        )
        QuickActionsRow(
            onCalendarClick = onCalendarClick,
            onSettingsClick = onSettingsClick
        )
        MotivationFooter()
    }
}
