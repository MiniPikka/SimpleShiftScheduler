package com.simpleshift.scheduler.ui.home.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp

@Composable
fun QuickActionsRow(
    onCalendarClick: () -> Unit,
    onSettingsClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        FilledTonalButton(
            onClick = onCalendarClick,
            modifier = Modifier.weight(1f)
        ) {
            Text("📅 日历")
        }
        FilledTonalButton(
            onClick = onSettingsClick,
            modifier = Modifier.weight(1f)
        ) {
            Text("⏰ 提醒")
        }
        FilledTonalButton(
            onClick = onSettingsClick,
            modifier = Modifier.weight(1f)
        ) {
            Text("⚙️ 设置")
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun QuickActionsRowPreview() {
    QuickActionsRow(
        onCalendarClick = {},
        onSettingsClick = {}
    )
}
