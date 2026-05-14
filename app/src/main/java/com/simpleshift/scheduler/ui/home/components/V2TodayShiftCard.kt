package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.ui.theme.V2CardShape
import com.simpleshift.scheduler.ui.theme.V2Danger
import com.simpleshift.scheduler.ui.theme.V2Success
import com.simpleshift.scheduler.ui.theme.V2Warning
import com.simpleshift.scheduler.ui.theme.v2ShiftColor

@Composable
fun V2TodayShiftCard(
    shiftLabel: String,
    shiftType: ShiftType,
    dayOfCycle: Int,
    totalDays: Int,
    daysUntilRest: Int,
    workIntensity: Int,
    modifier: Modifier = Modifier
) {
    val accentColor = v2ShiftColor(shiftType)
    val cardBg = accentColor.copy(alpha = 0.08f)
    val progress = if (totalDays > 0) dayOfCycle.toFloat() / totalDays else 0f
    val onBg = MaterialTheme.colorScheme.onBackground
    val onSv = MaterialTheme.colorScheme.onSurfaceVariant

    AnimatedVisibility(
        visible = true,
        enter = fadeIn() + slideInVertically { it / 3 },
        modifier = modifier
    ) {
        Surface(
            shape = V2CardShape,
            color = cardBg,
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(modifier = Modifier.height(240.dp)) {
                // Left accent bar
                Box(
                    modifier = Modifier
                        .width(4.dp)
                        .fillMaxHeight()
                        .background(accentColor)
                )

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(20.dp),
                    verticalArrangement = Arrangement.SpaceBetween
                ) {
                    // Top row: badge + title
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        // Circle badge with shift label
                        Surface(
                            shape = CircleShape,
                            color = accentColor,
                            modifier = Modifier.size(72.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    text = shiftLabel,
                                    style = MaterialTheme.typography.headlineLarge.copy(
                                        fontSize = MaterialTheme.typography.headlineLarge.fontSize,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White
                                    ),
                                    modifier = Modifier.align(Alignment.Center)
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(16.dp))
                        Column {
                            Text(
                                text = "今日班次",
                                style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                            )
                            val (intensityLabel, intensityColor) = when {
                                workIntensity <= 40 -> "轻松" to V2Success
                                workIntensity <= 70 -> "适中" to V2Warning
                                else -> "忙碌" to V2Danger
                            }
                            Text(
                                text = "牛马指数 $intensityLabel",
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    color = intensityColor,
                                    fontWeight = FontWeight.SemiBold
                                )
                            )
                        }
                    }

                    // Middle: rest info
                    val restText = if (daysUntilRest == 0) "今天休息"
                    else "距休 $daysUntilRest 天"
                    val restColor = if (daysUntilRest == 0) V2Success else onSv
                    Text(
                        text = restText,
                        style = MaterialTheme.typography.bodyMedium.copy(
                            color = restColor,
                            fontWeight = FontWeight.Medium
                        )
                    )

                    // Bottom: progress
                    Column {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "周期进度",
                                style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                            )
                            Text(
                                text = "$dayOfCycle / $totalDays",
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    color = onBg,
                                    fontWeight = FontWeight.Medium
                                )
                            )
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        LinearProgressIndicator(
                            progress = progress,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(6.dp)
                                .clip(MaterialTheme.shapes.small),
                            color = accentColor,
                            trackColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
                        )
                    }
                }
            }
        }
    }
}
