package com.simpleshift.scheduler.ui.home.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp

@Composable
fun StatsGrid(
    monthlyWorkDays: Int,
    totalDaysInMonth: Int,
    consecutiveWorkDays: Int,
    daysUntilRest: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        StatItem(
            value = "$monthlyWorkDays",
            label = "本月上班 / $totalDaysInMonth 天",
            modifier = Modifier.weight(1f)
        )
        StatItem(
            value = "$consecutiveWorkDays",
            label = "连续上班 天",
            modifier = Modifier.weight(1f)
        )
        StatItem(
            value = "$daysUntilRest",
            label = "距休班 天",
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun StatItem(
    value: String,
    label: String,
    modifier: Modifier = Modifier
) {
    Card(modifier = modifier) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally
        ) {
            Text(
                text = value,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun StatsGridPreview() {
    MaterialTheme {
        StatsGrid(
            monthlyWorkDays = 10,
            totalDaysInMonth = 22,
            consecutiveWorkDays = 3,
            daysUntilRest = 2
        )
    }
}
