package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import java.time.LocalTime

@Composable
fun V2GreetingHeader(
    teamName: String,
    dateText: String,
    shiftTimeRange: String? = null,
    modifier: Modifier = Modifier
) {
    val hour = LocalTime.now().hour
    val greeting = when (hour) {
        in 5..11 -> "早上好"
        in 12..17 -> "下午好"
        in 18..22 -> "晚上好"
        else -> "夜班辛苦了"
    }
    val onBg = MaterialTheme.colorScheme.onBackground
    val onSv = MaterialTheme.colorScheme.onSurfaceVariant

    Column(modifier = modifier.fillMaxWidth()) {
        AnimatedVisibility(
            visible = true,
            enter = fadeIn() + slideInVertically { it / 2 }
        ) {
            Column {
                Text(
                    text = "$greeting，$teamName",
                    style = MaterialTheme.typography.headlineLarge.copy(color = onBg)
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = dateText,
                    style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                )
                shiftTimeRange?.let { time ->
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = "今日提醒 $time",
                        style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
                    )
                }
            }
        }
    }
}
