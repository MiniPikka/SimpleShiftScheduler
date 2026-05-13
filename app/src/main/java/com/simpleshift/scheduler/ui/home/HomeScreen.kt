package com.simpleshift.scheduler.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.ui.common.TeamDropdown
import com.simpleshift.scheduler.viewmodel.HomeUiState

@Composable
fun HomeScreen(
    uiState: HomeUiState,
    onTeamSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 4.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        TeamDropdown(
            selectedTeamId = uiState.selectedTeamId,
            availableTeams = uiState.availableTeams,
            onTeamSelected = onTeamSelected
        )

        Text(
            text = "今日日期: ${uiState.todayDate}",
            style = MaterialTheme.typography.titleMedium
        )
        Text(
            text = "班次: ${uiState.shiftLabel}",
            style = MaterialTheme.typography.headlineMedium
        )
        Text(
            text = "进度: ${uiState.dayOfCycle} / ${uiState.totalDays}",
            style = MaterialTheme.typography.titleMedium
        )
    }
}
