package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.ui.theme.V2ButtonShape

@Composable
fun V2QuickActionsRow(
    onCalendarClick: () -> Unit,
    onSettingsClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    AnimatedVisibility(
        visible = true,
        enter = fadeIn() + slideInVertically { it / 3 },
        modifier = modifier
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            FilledTonalButton(
                onClick = onCalendarClick,
                modifier = Modifier.weight(1f),
                shape = V2ButtonShape
            ) {
                Icon(
                    imageVector = Icons.Outlined.CalendarMonth,
                    contentDescription = null
                )
                Text("日历", modifier = Modifier.weight(1f))
            }
            FilledTonalButton(
                onClick = onSettingsClick,
                modifier = Modifier.weight(1f),
                shape = V2ButtonShape
            ) {
                Icon(
                    imageVector = Icons.Outlined.Notifications,
                    contentDescription = null
                )
                Text("提醒", modifier = Modifier.weight(1f))
            }
            FilledTonalButton(
                onClick = onSettingsClick,
                modifier = Modifier.weight(1f),
                shape = V2ButtonShape
            ) {
                Icon(
                    imageVector = Icons.Outlined.Settings,
                    contentDescription = null
                )
                Text("设置", modifier = Modifier.weight(1f))
            }
        }
    }
}
