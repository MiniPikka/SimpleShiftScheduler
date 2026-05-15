package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.ui.theme.v2ShiftColor
import java.time.LocalTime

@Composable
fun V3ShiftHeroBanner(
    shiftLabel: String,
    shiftType: ShiftType,
    dateText: String,
    teamName: String,
    shiftTimeRange: String? = null,
    modifier: Modifier = Modifier
) {
    val accentColor = v2ShiftColor(shiftType)
    val onSv = MaterialTheme.colorScheme.onSurfaceVariant
    val surface = MaterialTheme.colorScheme.surface

    val hour = LocalTime.now().hour
    val greeting = when (hour) {
        in 5..11 -> "早上好"
        in 12..17 -> "下午好"
        in 18..22 -> "晚上好"
        else -> "夜班辛苦了"
    }

    val gradientBrush = Brush.verticalGradient(
        colors = listOf(
            accentColor.copy(alpha = 0.10f),
            accentColor.copy(alpha = 0.02f),
            surface
        ),
        startY = 0f,
        endY = Float.POSITIVE_INFINITY
    )

    AnimatedVisibility(
        visible = true,
        enter = fadeIn() + slideInVertically { it / 4 },
        modifier = modifier
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(gradientBrush)
                .padding(horizontal = 20.dp, vertical = 24.dp)
        ) {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "$greeting，$teamName",
                    style = MaterialTheme.typography.bodyLarge.copy(color = onSv)
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = dateText,
                    style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                )

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = shiftLabel,
                    fontSize = 48.sp,
                    fontWeight = FontWeight.Bold,
                    color = accentColor,
                    textAlign = TextAlign.Center
                )

                shiftTimeRange?.let { time ->
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "今日提醒 $time",
                        style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                    )
                }
            }
        }
    }
}
