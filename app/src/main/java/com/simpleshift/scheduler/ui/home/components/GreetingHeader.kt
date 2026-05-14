package com.simpleshift.scheduler.ui.home.components

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import java.time.LocalTime

@Composable
fun GreetingHeader(
    teamName: String,
    dateText: String,
    modifier: Modifier = Modifier
) {
    val greeting = when (LocalTime.now().hour) {
        in 5..11 -> "早上好"
        in 12..17 -> "下午好"
        in 18..22 -> "晚上好"
        else -> "夜班辛苦了"
    }

    Column(modifier = modifier) {
        Text(
            text = "$greeting，$teamName",
            style = MaterialTheme.typography.headlineMedium
        )
        Text(
            text = dateText,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun GreetingHeaderPreview() {
    MaterialTheme {
        GreetingHeader(
            teamName = "一值",
            dateText = "2026年5月13日 星期三"
        )
    }
}
