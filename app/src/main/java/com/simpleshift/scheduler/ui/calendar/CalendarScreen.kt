package com.simpleshift.scheduler.ui.calendar

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.R
import com.simpleshift.scheduler.domain.model.MonthlyStats
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import com.simpleshift.scheduler.ui.common.TeamDropdown
import com.simpleshift.scheduler.ui.theme.v2ShiftColor
import com.simpleshift.scheduler.util.ShiftLabelMapper
import com.simpleshift.scheduler.viewmodel.CalendarDayUiState
import com.simpleshift.scheduler.viewmodel.CalendarUiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarScreen(
    uiState: CalendarUiState,
    onPreviousMonthClick: () -> Unit,
    onNextMonthClick: () -> Unit,
    onTodayClick: () -> Unit,
    onStatsClick: () -> Unit,
    onNavigateBack: () -> Unit,
    onTeamSelected: (Int) -> Unit,
    availableTeams: List<Team>,
    modifier: Modifier = Modifier
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.calendar_title)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.calendar_return)
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            TeamDropdown(
                selectedTeamId = uiState.selectedTeamId,
                availableTeams = availableTeams,
                onTeamSelected = onTeamSelected
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
            ) {
                IconButton(onClick = onPreviousMonthClick) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                        contentDescription = stringResource(R.string.calendar_prev_month)
                    )
                }
                Text(
                    text = uiState.monthLabel,
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center
                )
                IconButton(onClick = onNextMonthClick) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = stringResource(R.string.calendar_next_month)
                    )
                }
                if (!uiState.isCurrentMonth) {
                    TextButton(onClick = onTodayClick) {
                        Text(stringResource(R.string.calendar_today))
                    }
                }
                IconButton(onClick = onStatsClick) {
                    Icon(
                        imageVector = Icons.Filled.BarChart,
                        contentDescription = stringResource(R.string.calendar_stats)
                    )
                }
            }

            // Week header row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                uiState.weekLabels.forEach { week ->
                    Text(
                        text = week,
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.labelLarge,
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            // 6 rows of 7 date cells each (42 total)
            val dayRows = uiState.days.chunked(7)
            dayRows.forEach { rowDays ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    rowDays.forEach { day ->
                        CalendarDayCell(
                            day = day,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }

            // Inline stats below calendar grid
            uiState.stats?.let { stats ->
                StatsCard(stats = stats)
            }
        }
    }
}

@Composable
private fun StatsCard(stats: MonthlyStats) {
    val context = LocalContext.current
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            InlineStatItem(label = ShiftLabelMapper.toFullLabel(context, ShiftType.MORNING), count = stats.morningCount)
            InlineStatItem(label = ShiftLabelMapper.toFullLabel(context, ShiftType.AFTERNOON), count = stats.afternoonCount)
            InlineStatItem(label = ShiftLabelMapper.toFullLabel(context, ShiftType.REST), count = stats.restCount)
            InlineStatItem(label = ShiftLabelMapper.toFullLabel(context, ShiftType.NIGHT), count = stats.nightCount)
            InlineStatItem(label = ShiftLabelMapper.toFullLabel(context, ShiftType.STUDY), count = stats.studyCount)
        }
    }
}

@Composable
private fun InlineStatItem(label: String, count: Int) {
    Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
        Text(
            text = "$count",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun CalendarDayCell(day: CalendarDayUiState, modifier: Modifier = Modifier) {
    val accentColor = v2ShiftColor(day.shiftType)
    val bgAlpha = if (day.isCurrentMonth) 0.12f else 0.04f
    val containerColor = accentColor.copy(alpha = bgAlpha)

    val border = if (day.isToday) {
        BorderStroke(2.dp, MaterialTheme.colorScheme.primary)
    } else {
        BorderStroke(0.5.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.3f))
    }

    val contentColor = if (day.isCurrentMonth) {
        MaterialTheme.colorScheme.onSurface
    } else {
        MaterialTheme.colorScheme.onSurface.copy(alpha = 0.35f)
    }
    val shiftTextColor = if (day.isCurrentMonth) {
        accentColor
    } else {
        accentColor.copy(alpha = 0.4f)
    }

    Card(
        modifier = modifier.aspectRatio(0.85f),
        border = border,
        colors = CardDefaults.cardColors(containerColor = containerColor)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 6.dp),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(
                text = day.dateNumber.toString(),
                textAlign = TextAlign.Center,
                color = contentColor,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.fillMaxWidth()
            )
            Text(
                text = day.shiftLabel,
                textAlign = TextAlign.Center,
                color = shiftTextColor,
                style = MaterialTheme.typography.titleSmall,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
