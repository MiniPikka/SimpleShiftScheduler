package com.simpleshift.scheduler.ui.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.People
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
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
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.ui.home.components.getContextualMessage
import com.simpleshift.scheduler.ui.theme.V2CardShape
import com.simpleshift.scheduler.ui.theme.V2Danger
import com.simpleshift.scheduler.ui.theme.V2Rest
import com.simpleshift.scheduler.ui.theme.V2Success
import com.simpleshift.scheduler.ui.theme.V2Warning
import com.simpleshift.scheduler.ui.theme.v2ShiftColor
import com.simpleshift.scheduler.viewmodel.HomeUiState
import java.time.LocalTime

@Composable
fun NewHomeScreenV4(
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
            .padding(horizontal = 16.dp)
    ) {
        Spacer(modifier = Modifier.height(12.dp))

        V4GreetingRow(
            dateText = uiState.todayDate,
            teamName = uiState.teamName
        )

        Spacer(modifier = Modifier.height(16.dp))

        V4HeroCard(
            shiftLabel = uiState.shiftLabel,
            shiftType = uiState.shiftType,
            shiftTimeRange = uiState.shiftTimeRange,
            dayOfCycle = uiState.dayOfCycle,
            totalDays = uiState.totalDays,
            daysUntilRest = uiState.daysUntilRest
        )

        Spacer(modifier = Modifier.height(16.dp))

        V4StatsRow(
            monthlyWorkDays = uiState.monthlyWorkDays,
            totalDaysInMonth = uiState.totalDaysInMonth,
            consecutiveWorkDays = uiState.consecutiveWorkDays,
            workIntensity = uiState.workIntensity,
            shiftType = uiState.shiftType
        )

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = "快捷工具",
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 4.dp)
        )

        Spacer(modifier = Modifier.height(10.dp))

        V4ToolsRow(
            onLeaveOptimizerClick = onLeaveOptimizerClick,
            onColleagueModeClick = onColleagueModeClick,
            onSalaryPredictorClick = onSalaryPredictorClick
        )

        Spacer(modifier = Modifier.height(20.dp))

        V4MessageBanner(
            shiftType = uiState.shiftType,
            daysUntilRest = uiState.daysUntilRest,
            consecutiveWorkDays = uiState.consecutiveWorkDays
        )

        Spacer(modifier = Modifier.height(24.dp))
    }
}

// ── Greeting ──────────────────────────────────────────────

@Composable
private fun V4GreetingRow(
    dateText: String,
    teamName: String,
    modifier: Modifier = Modifier
) {
    val hour = LocalTime.now().hour
    val greeting = when (hour) {
        in 5..11 -> "早上好"
        in 12..17 -> "下午好"
        in 18..22 -> "晚上好"
        else -> "夜班辛苦了"
    }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text(
                text = "$greeting，$teamName",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onBackground
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = dateText,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// ── Hero Card ─────────────────────────────────────────────

@Composable
private fun V4HeroCard(
    shiftLabel: String,
    shiftType: ShiftType,
    shiftTimeRange: String?,
    dayOfCycle: Int,
    totalDays: Int,
    daysUntilRest: Int,
    modifier: Modifier = Modifier
) {
    val accentColor = v2ShiftColor(shiftType)
    val onSv = MaterialTheme.colorScheme.onSurfaceVariant
    val onBg = MaterialTheme.colorScheme.onBackground
    val firstChar = shiftLabel.firstOrNull()?.toString() ?: "?"
    val progress = if (totalDays > 0) dayOfCycle.toFloat() / totalDays else 0f

    var animatedVisible by remember { mutableStateOf(false) }
    animatedVisible = true

    AnimatedVisibility(
        visible = animatedVisible,
        enter = fadeIn() + slideInVertically { it / 4 }
    ) {
        Surface(
            shape = V2CardShape,
            color = MaterialTheme.colorScheme.surface,
            modifier = modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(20.dp)) {

                // Top row: circle badge + shift info
                Row(verticalAlignment = Alignment.CenterVertically) {

                    // Circle badge with first shift character
                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .background(color = accentColor, shape = CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = firstChar,
                            color = Color.White,
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Spacer(modifier = Modifier.width(16.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = shiftLabel,
                            fontSize = 26.sp,
                            fontWeight = FontWeight.Bold,
                            color = onBg
                        )

                        if (shiftTimeRange != null) {
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "提醒 $shiftTimeRange",
                                style = MaterialTheme.typography.bodyMedium,
                                color = onSv
                            )
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        // Rest countdown chip
                        V4RestChip(
                            daysUntilRest = daysUntilRest,
                            shiftType = shiftType
                        )
                    }
                }

                Spacer(modifier = Modifier.height(18.dp))

                // Cycle progress
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "第 $dayOfCycle 天 · 共 $totalDays 天",
                        style = MaterialTheme.typography.bodyMedium,
                        color = onSv
                    )
                    Text(
                        text = "${(progress * 100).toInt()}%",
                        style = MaterialTheme.typography.bodyMedium,
                        color = accentColor,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(6.dp)
                        .clip(RoundedCornerShape(3.dp)),
                    color = accentColor,
                    trackColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                )
            }
        }
    }
}

@Composable
private fun V4RestChip(
    daysUntilRest: Int,
    shiftType: ShiftType
) {
    val bgColor: Color
    val textColor: Color
    val text: String

    when {
        shiftType == ShiftType.REST -> {
            bgColor = V2Rest.copy(alpha = 0.12f)
            textColor = V2Rest
            text = "今日休息"
        }
        daysUntilRest == 0 -> {
            bgColor = V2Success.copy(alpha = 0.12f)
            textColor = V2Success
            text = "明天休息！"
        }
        else -> {
            bgColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
            textColor = MaterialTheme.colorScheme.onSurfaceVariant
            text = "距下次休息 $daysUntilRest 天"
        }
    }

    Surface(
        shape = RoundedCornerShape(12.dp),
        color = bgColor
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = textColor,
            fontWeight = FontWeight.Medium
        )
    }
}

// ── Stats Row ─────────────────────────────────────────────

@Composable
private fun V4StatsRow(
    monthlyWorkDays: Int,
    totalDaysInMonth: Int,
    consecutiveWorkDays: Int,
    workIntensity: Int,
    shiftType: ShiftType,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Monthly work days
        V4StatCard(
            label = "本月上班",
            value = "$monthlyWorkDays",
            unit = "/$totalDaysInMonth 天",
            accentLabel = when {
                workIntensity <= 40 -> "轻松"
                workIntensity <= 70 -> "适中"
                else -> "忙碌"
            },
            accentColor = when {
                workIntensity <= 40 -> V2Success
                workIntensity <= 70 -> V2Warning
                else -> V2Danger
            },
            modifier = Modifier.weight(1f)
        )

        // Consecutive work days
        val consecutiveLabel: String
        val consecutiveColor: Color
        when {
            shiftType == ShiftType.REST -> {
                consecutiveLabel = "今日休息"
                consecutiveColor = V2Success
            }
            consecutiveWorkDays >= 5 -> {
                consecutiveLabel = "需要休息"
                consecutiveColor = V2Danger
            }
            consecutiveWorkDays >= 3 -> {
                consecutiveLabel = "注意调节"
                consecutiveColor = V2Warning
            }
            else -> {
                consecutiveLabel = "状态良好"
                consecutiveColor = V2Success
            }
        }

        V4StatCard(
            label = "连续上班",
            value = if (shiftType == ShiftType.REST) "0" else "$consecutiveWorkDays",
            unit = "天",
            accentLabel = consecutiveLabel,
            accentColor = consecutiveColor,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun V4StatCard(
    label: String,
    value: String,
    unit: String,
    accentLabel: String,
    accentColor: Color,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = V2CardShape,
        color = MaterialTheme.colorScheme.surface,
        modifier = modifier
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(6.dp))
            Row(verticalAlignment = Alignment.Bottom) {
                Text(
                    text = value,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onBackground
                )
                Spacer(modifier = Modifier.width(2.dp))
                Text(
                    text = unit,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = accentLabel,
                style = MaterialTheme.typography.bodyMedium,
                color = accentColor,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

// ── Tools Row ─────────────────────────────────────────────

@Composable
private fun V4ToolsRow(
    onLeaveOptimizerClick: () -> Unit,
    onColleagueModeClick: () -> Unit,
    onSalaryPredictorClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        V4ToolCard(
            icon = {
                Icon(
                    Icons.Filled.CalendarMonth,
                    contentDescription = null,
                    tint = Color(0xFFFFB347),
                    modifier = Modifier.size(28.dp)
                )
            },
            label = "拼假神器",
            onClick = onLeaveOptimizerClick,
            modifier = Modifier.weight(1f)
        )
        V4ToolCard(
            icon = {
                Icon(
                    Icons.Filled.People,
                    contentDescription = null,
                    tint = Color(0xFF4DA3FF),
                    modifier = Modifier.size(28.dp)
                )
            },
            label = "同事模式",
            onClick = onColleagueModeClick,
            modifier = Modifier.weight(1f)
        )
        V4ToolCard(
            icon = {
                Icon(
                    Icons.Filled.AttachMoney,
                    contentDescription = null,
                    tint = Color(0xFF7C5CFF),
                    modifier = Modifier.size(28.dp)
                )
            },
            label = "倒班津贴",
            onClick = onSalaryPredictorClick,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun V4ToolCard(
    icon: @Composable () -> Unit,
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = V2CardShape,
        color = MaterialTheme.colorScheme.surface,
        modifier = modifier.clickable(onClick = onClick)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            icon()
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = label,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Medium,
                textAlign = TextAlign.Center
            )
        }
    }
}

// ── Message Banner ────────────────────────────────────────

@Composable
private fun V4MessageBanner(
    shiftType: ShiftType,
    daysUntilRest: Int,
    consecutiveWorkDays: Int,
    modifier: Modifier = Modifier
) {
    val message = getContextualMessage(shiftType, daysUntilRest, consecutiveWorkDays)

    Surface(
        shape = V2CardShape,
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f),
        modifier = modifier.fillMaxWidth()
    ) {
        Text(
            text = message,
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}
