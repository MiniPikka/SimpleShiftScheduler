package com.simpleshift.scheduler.ui.home

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.ui.home.components.V3ContextualMessage
import com.simpleshift.scheduler.ui.home.components.V3FeatureHub
import com.simpleshift.scheduler.ui.home.components.V3MonthlyOverview
import com.simpleshift.scheduler.ui.home.components.V3ProgressIndicator
import com.simpleshift.scheduler.ui.home.components.V3RestCountdownCard
import com.simpleshift.scheduler.ui.home.components.V3ShiftHeroBanner
import com.simpleshift.scheduler.viewmodel.HomeUiState

@Composable
fun NewHomeScreenV3(
    uiState: HomeUiState,
    onLeaveOptimizerClick: () -> Unit,
    onColleagueModeClick: () -> Unit,
    onSalaryPredictorClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
    ) {
        V3ShiftHeroBanner(
            shiftLabel = uiState.shiftLabel,
            shiftType = uiState.shiftType,
            dateText = uiState.todayDate,
            teamName = uiState.teamName,
            shiftTimeRange = uiState.shiftTimeRange
        )

        Spacer(modifier = Modifier.height(16.dp))

        V3RestCountdownCard(
            daysUntilRest = uiState.daysUntilRest,
            shiftType = uiState.shiftType
        )

        Spacer(modifier = Modifier.height(20.dp))

        V3FeatureHub(
            onLeaveOptimizerClick = onLeaveOptimizerClick,
            onColleagueModeClick = onColleagueModeClick,
            onSalaryPredictorClick = onSalaryPredictorClick
        )

        Spacer(modifier = Modifier.height(12.dp))

        V3ProgressIndicator(
            dayOfCycle = uiState.dayOfCycle,
            totalDays = uiState.totalDays,
            shiftType = uiState.shiftType
        )

        Spacer(modifier = Modifier.height(24.dp))

        V3MonthlyOverview(
            monthlyWorkDays = uiState.monthlyWorkDays,
            totalDaysInMonth = uiState.totalDaysInMonth,
            workIntensity = uiState.workIntensity,
            consecutiveWorkDays = uiState.consecutiveWorkDays
        )

        Spacer(modifier = Modifier.height(16.dp))

        V3ContextualMessage(
            shiftType = uiState.shiftType,
            daysUntilRest = uiState.daysUntilRest,
            consecutiveWorkDays = uiState.consecutiveWorkDays
        )

        Spacer(modifier = Modifier.height(24.dp))
    }
}
