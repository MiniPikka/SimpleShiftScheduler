package com.simpleshift.scheduler.ui.calendar

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.domain.model.MonthlyStats
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.viewmodel.CalendarDayUiState
import com.simpleshift.scheduler.viewmodel.CalendarUiState

@Composable
fun CalendarScreen(
    uiState: CalendarUiState,
    onPreviousMonthClick: () -> Unit,
    onNextMonthClick: () -> Unit,
    onTodayClick: () -> Unit,
    onStatsClick: () -> Unit,
    onDismissStats: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
        ) {
            IconButton(onClick = onPreviousMonthClick) {
                Icon(
                    imageVector = Icons.Filled.KeyboardArrowLeft,
                    contentDescription = "上月"
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
                    imageVector = Icons.Filled.KeyboardArrowRight,
                    contentDescription = "下月"
                )
            }
            if (!uiState.isCurrentMonth) {
                TextButton(onClick = onTodayClick) {
                    Text("今天")
                }
            }
            IconButton(onClick = onStatsClick) {
                Icon(
                    imageVector = Icons.Filled.BarChart,
                    contentDescription = "统计"
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
    }

    uiState.stats?.let { stats ->
        StatsDialog(
            stats = stats,
            onDismiss = onDismissStats
        )
    }
}

@Composable
private fun StatsDialog(
    stats: MonthlyStats,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("月度统计") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                StatsRow(label = "早班", count = stats.morningCount)
                StatsRow(label = "中班", count = stats.afternoonCount)
                StatsRow(label = "休息班", count = stats.restCount)
                StatsRow(label = "夜班", count = stats.nightCount)
                StatsRow(label = "学习班", count = stats.studyCount)
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("确定")
            }
        }
    )
}

@Composable
private fun StatsRow(label: String, count: Int) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = label, style = MaterialTheme.typography.bodyLarge)
        Text(text = "$count 天", style = MaterialTheme.typography.bodyLarge)
    }
}

@Composable
private fun CalendarDayCell(day: CalendarDayUiState, modifier: Modifier = Modifier) {
    val shiftColor = when (day.shiftType) {
        ShiftType.MORNING -> Color(0xFFFFF3E0)
        ShiftType.AFTERNOON -> Color(0xFFE3F2FD)
        ShiftType.REST -> Color(0xFFE8F5E9)
        ShiftType.NIGHT -> Color(0xFFEDE7F6)
        ShiftType.STUDY -> Color(0xFFFFF8E1)
    }

    val alpha = if (day.isCurrentMonth) 1f else 0.45f
    val containerColor = shiftColor.copy(alpha = alpha)

    val border = if (day.isToday) {
        BorderStroke(2.dp, Color(0xFF1976D2))
    } else {
        BorderStroke(1.dp, Color.LightGray)
    }

    val contentColor = if (day.isCurrentMonth) {
        Color(0xFF212121)
    } else {
        Color(0xFF9E9E9E)
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
                color = contentColor,
                style = MaterialTheme.typography.titleSmall,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

