package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.ui.theme.v2ShiftColor

@Composable
fun V3ProgressIndicator(
    dayOfCycle: Int,
    totalDays: Int,
    shiftType: ShiftType,
    modifier: Modifier = Modifier
) {
    val accentColor = v2ShiftColor(shiftType)
    val onSv = MaterialTheme.colorScheme.onSurfaceVariant
    val onBg = MaterialTheme.colorScheme.onBackground
    val progress = if (totalDays > 0) dayOfCycle.toFloat() / totalDays else 0f

    AnimatedVisibility(
        visible = true,
        enter = fadeIn(),
        modifier = modifier
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "本轮周期",
                    style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                )
                Text(
                    text = "第 $dayOfCycle 天 · 共 $totalDays 天",
                    style = MaterialTheme.typography.bodyMedium.copy(
                        color = onBg,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
            Spacer(modifier = Modifier.height(6.dp))
            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .clip(MaterialTheme.shapes.small),
                color = accentColor,
                trackColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f),
            )
        }
    }
}
