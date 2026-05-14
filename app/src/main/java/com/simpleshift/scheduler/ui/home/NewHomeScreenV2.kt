package com.simpleshift.scheduler.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.ui.home.components.V2GreetingHeader
import com.simpleshift.scheduler.ui.home.components.V2MotivationFooter
import com.simpleshift.scheduler.ui.home.components.V2StatsGrid
import com.simpleshift.scheduler.ui.home.components.V2TodayShiftCard
import com.simpleshift.scheduler.viewmodel.HomeUiState

@Composable
fun NewHomeScreenV2(
    uiState: HomeUiState,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        V2GreetingHeader(
            teamName = uiState.teamName,
            dateText = uiState.todayDate,
            shiftTimeRange = uiState.shiftTimeRange
        )

        V2TodayShiftCard(
            shiftLabel = uiState.shiftLabel,
            shiftType = uiState.shiftType,
            dayOfCycle = uiState.dayOfCycle,
            totalDays = uiState.totalDays,
            daysUntilRest = uiState.daysUntilRest,
            workIntensity = uiState.workIntensity
        )

        V2StatsGrid(
            monthlyWorkDays = uiState.monthlyWorkDays,
            totalDaysInMonth = uiState.totalDaysInMonth,
            consecutiveWorkDays = uiState.consecutiveWorkDays,
            daysUntilRest = uiState.daysUntilRest
        )

        V2MotivationFooter()

        Spacer(modifier = Modifier.height(16.dp))
    }
}
