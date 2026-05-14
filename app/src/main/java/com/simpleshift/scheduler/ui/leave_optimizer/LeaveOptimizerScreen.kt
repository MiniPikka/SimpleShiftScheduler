package com.simpleshift.scheduler.ui.leave_optimizer

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.simpleshift.scheduler.domain.model.LeaveStrategy
import com.simpleshift.scheduler.viewmodel.LeaveOptimizerViewModel
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LeaveOptimizerScreen(
    uiState: LeaveOptimizerViewModel.LeaveOptimizerUiState,
    onNavigateBack: () -> Unit,
    onMaxLeaveDaysChanged: (Int) -> Unit
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("拼假神器") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Description header
            Column(
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp)
            ) {
                Text(
                    text = "基于你的倒班表 + 法定节假日",
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (uiState.analyzedDateRange.isNotEmpty()) {
                    Text(
                        text = "今日至年底 · ${uiState.analyzedDateRange}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                    )
                }
            }

            // Filter chips
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "最多请假：",
                    style = MaterialTheme.typography.labelMedium,
                    modifier = Modifier.align(Alignment.CenterVertically),
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                val leaveOptions = listOf(1, 2, 3, 4, 5)
                leaveOptions.forEach { days ->
                    FilterChip(
                        selected = uiState.maxLeaveDays == days,
                        onClick = { onMaxLeaveDaysChanged(days) },
                        label = { Text("${days}天") },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Content
            when {
                uiState.isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }

                uiState.errorMessage != null -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = uiState.errorMessage,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyLarge,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(32.dp)
                        )
                    }
                }

                uiState.strategies.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "未找到高效请假方案",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "当前倒班表下所有工作间隙都超过 ${uiState.maxLeaveDays} 天\n尝试增加请假天数",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }

                else -> {
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(horizontal = 16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        itemsIndexed(uiState.strategies, key = { _, s ->
                            "${s.breakStart}_${s.breakEnd}_${s.leaveDays}"
                        }) { index, strategy ->
                            AnimatedVisibility(
                                visible = true,
                                enter = fadeIn() + slideInVertically(
                                    initialOffsetY = { it * (index.coerceAtMost(5) + 1) }
                                )
                            ) {
                                StrategyCard(
                                    strategy = strategy,
                                    rank = index + 1
                                )
                            }
                        }
                        item { Spacer(modifier = Modifier.height(16.dp)) }
                    }
                }
            }
        }
    }
}

@Composable
private fun StrategyCard(strategy: LeaveStrategy, rank: Int) {
    val borderColor = when (rank) {
        1 -> Color(0xFFFFD700) // Gold
        2 -> Color(0xFFC0C0C0) // Silver
        3 -> Color(0xFFCD7F32) // Bronze
        else -> Color.Transparent
    }
    val borderWidth = if (rank <= 3) 2.dp else 0.dp

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (borderWidth > 0.dp) Modifier.border(borderWidth, borderColor, RoundedCornerShape(24.dp))
                else Modifier
            ),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Top row: efficiency badge + medal
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (rank == 1) Text("🥇", fontSize = 18.sp)
                    else if (rank == 2) Text("🥈", fontSize = 18.sp)
                    else if (rank == 3) Text("🥉", fontSize = 18.sp)

                    Text(
                        text = "请假 ${strategy.leaveDays} 天 → 连休 ${strategy.totalBreakDays} 天",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                // Efficiency badge
                EfficiencyBadge(strategy.efficiency)
            }

            Spacer(modifier = Modifier.height(6.dp))

            // Date range
            val dateFmt = DateTimeFormatter.ofPattern("M月d日")
            Text(
                text = "${strategy.breakStart.format(dateFmt)} — ${strategy.breakEnd.format(dateFmt)}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            // Holiday overlap badges
            if (strategy.overlappingHolidayNames.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    strategy.overlappingHolidayNames.forEach { name ->
                        HolidayBadge(name)
                    }
                }
            }
            if (strategy.weekendOverlap > 0 && strategy.holidayOverlap == 0) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "含${strategy.weekendOverlap}个周末日",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Mini bar: 30-day window centered on break
            MiniCalendarBar(strategy)
        }
    }
}

@Composable
private fun EfficiencyBadge(efficiency: Float) {
    val bgColor = when {
        efficiency >= 4.0f -> Color(0xFF22C55E).copy(alpha = 0.15f)
        efficiency >= 3.0f -> Color(0xFFF59E0B).copy(alpha = 0.15f)
        efficiency >= 2.0f -> Color(0xFF4DA3FF).copy(alpha = 0.15f)
        else -> MaterialTheme.colorScheme.surfaceVariant
    }
    val textColor = when {
        efficiency >= 4.0f -> Color(0xFF16A34A)
        efficiency >= 3.0f -> Color(0xFFD97706)
        efficiency >= 2.0f -> Color(0xFF2563EB)
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }

    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(bgColor)
            .padding(horizontal = 8.dp, vertical = 2.dp)
    ) {
        Text(
            text = "${"%.1f".format(efficiency)}x",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Bold,
            color = textColor
        )
    }
}

@Composable
private fun HolidayBadge(name: String) {
    val displayName = name.replace("[待确认]", "")
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(6.dp))
            .background(MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.5f))
            .padding(horizontal = 6.dp, vertical = 1.dp)
    ) {
        Text(
            text = "● $displayName",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onTertiaryContainer
        )
    }
}

@Composable
private fun MiniCalendarBar(strategy: LeaveStrategy) {
    // Show a 24-day window centered on the break period
    val windowDays = 24
    val breakStartDay = strategy.breakStart.toEpochDay()
    val breakEndDay = strategy.breakEnd.toEpochDay()

    // Center the break in the window
    val breakMiddle = (breakStartDay + breakEndDay) / 2
    val windowStartDay = breakMiddle - windowDays / 2
    val windowEndDay = windowStartDay + windowDays - 1

    // Convert leave dates to epoch days for quick lookup
    val leaveEpochDays = strategy.leaveDates.map { it.toEpochDay() }.toSet()

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(2.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        for (epochDay in windowStartDay..windowEndDay) {
            val isInBreak = epochDay in breakStartDay..breakEndDay
            val isLeave = epochDay in leaveEpochDays

            val color = when {
                isLeave -> MaterialTheme.colorScheme.primary
                isInBreak -> MaterialTheme.colorScheme.primary.copy(alpha = 0.4f)
                else -> MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)
            }

            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(color)
            )
        }
    }

    // Legend
    Spacer(modifier = Modifier.height(4.dp))
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(6.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary)
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = "请假",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.width(8.dp))
        Box(
            modifier = Modifier
                .size(6.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.4f))
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = "休息",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
