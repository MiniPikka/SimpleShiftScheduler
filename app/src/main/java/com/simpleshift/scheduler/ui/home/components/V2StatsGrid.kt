package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.ui.theme.V2CardShape

@Composable
fun V2StatsGrid(
    monthlyWorkDays: Int,
    totalDaysInMonth: Int,
    consecutiveWorkDays: Int,
    daysUntilRest: Int,
    modifier: Modifier = Modifier
) {
    AnimatedVisibility(
        visible = true,
        enter = fadeIn() + slideInVertically { it / 2 },
        modifier = modifier
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            V2StatsCard(
                value = "$monthlyWorkDays/$totalDaysInMonth",
                label = "本月上班",
                modifier = Modifier.weight(1f)
            )
            V2StatsCard(
                value = "${consecutiveWorkDays}天",
                label = "连续上班",
                modifier = Modifier.weight(1f)
            )
            V2StatsCard(
                value = "${daysUntilRest}天",
                label = "距休班",
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun V2StatsCard(
    value: String,
    label: String,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = V2CardShape,
        color = MaterialTheme.colorScheme.surface,
        modifier = modifier
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally
        ) {
            Text(
                text = value,
                style = MaterialTheme.typography.headlineMedium.copy(
                    color = MaterialTheme.colorScheme.onBackground,
                    fontWeight = FontWeight.Bold
                ),
                textAlign = TextAlign.Center
            )
            Text(
                text = label,
                style = MaterialTheme.typography.bodyMedium.copy(
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                ),
                textAlign = TextAlign.Center
            )
        }
    }
}
