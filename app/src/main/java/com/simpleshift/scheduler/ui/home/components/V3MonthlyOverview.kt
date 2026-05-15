package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.ui.theme.V2CardShape
import com.simpleshift.scheduler.ui.theme.V2Danger
import com.simpleshift.scheduler.ui.theme.V2Success
import com.simpleshift.scheduler.ui.theme.V2Warning

@Composable
fun V3MonthlyOverview(
    monthlyWorkDays: Int,
    totalDaysInMonth: Int,
    workIntensity: Int,
    consecutiveWorkDays: Int,
    modifier: Modifier = Modifier
) {
    val onBg = MaterialTheme.colorScheme.onBackground
    val onSv = MaterialTheme.colorScheme.onSurfaceVariant
    val surface = MaterialTheme.colorScheme.surface
    var expanded by remember { mutableStateOf(false) }

    val (intensityLabel, intensityColor) = when {
        workIntensity <= 40 -> "劳逸充裕" to V2Success
        workIntensity <= 70 -> "劳逸平衡" to V2Warning
        else -> "辛苦劳作" to V2Danger
    }

    AnimatedVisibility(
        visible = true,
        enter = fadeIn() + slideInVertically { it / 3 },
        modifier = modifier
    ) {
        Surface(
            shape = V2CardShape,
            color = surface,
            modifier = Modifier
                .fillMaxWidth()
                .animateContentSize()
                .clickable { expanded = !expanded }
        ) {
            Column(
                modifier = Modifier.padding(if (expanded) 16.dp else 12.dp)
            ) {
                // Collapsed: summary line
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "本月上班 $monthlyWorkDays / $totalDaysInMonth 天",
                            style = MaterialTheme.typography.bodyLarge.copy(
                                color = onBg,
                                fontWeight = FontWeight.Medium
                            )
                        )
                        Text(
                            text = intensityLabel,
                            style = MaterialTheme.typography.bodyMedium.copy(
                                color = intensityColor,
                                fontWeight = FontWeight.SemiBold
                            )
                        )
                    }
                }

                // Expanded: detail rows
                AnimatedVisibility(visible = expanded) {
                    Column {
                        Spacer(modifier = Modifier.height(12.dp))

                        DetailRow(
                            label = "连续上班",
                            value = "${consecutiveWorkDays}天",
                            onBg = onBg, onSv = onSv
                        )
                        DetailRow(
                            label = "上班占比",
                            value = if (totalDaysInMonth > 0) {
                                "${(monthlyWorkDays * 100 / totalDaysInMonth)}%"
                            } else "—",
                            onBg = onBg, onSv = onSv
                        )
                        DetailRow(
                            label = "月度评价",
                            value = intensityLabel,
                            valueColor = intensityColor,
                            onBg = onBg, onSv = onSv
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun DetailRow(
    label: String,
    value: String,
    valueColor: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onBackground,
    onBg: androidx.compose.ui.graphics.Color,
    onSv: androidx.compose.ui.graphics.Color
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium.copy(color = onSv),
            modifier = Modifier.weight(1f)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium.copy(
                color = valueColor,
                fontWeight = FontWeight.Medium
            )
        )
    }
}
