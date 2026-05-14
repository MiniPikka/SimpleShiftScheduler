package com.simpleshift.scheduler.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.domain.model.Team
import com.simpleshift.scheduler.ui.common.TeamDropdown
import com.simpleshift.scheduler.ui.theme.V2CardShape

@Composable
fun ProfileScreen(
    selectedTeamId: Int,
    availableTeams: List<Team>,
    onTeamSelected: (Int) -> Unit,
    onRulesClick: () -> Unit,
    onAlarmClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val surface = MaterialTheme.colorScheme.surface
    val onBg = MaterialTheme.colorScheme.onBackground
    val onSv = MaterialTheme.colorScheme.onSurfaceVariant

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Team selection card
        Card(
            shape = V2CardShape,
            colors = CardDefaults.cardColors(containerColor = surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Filled.Groups,
                        contentDescription = null,
                        tint = onBg,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "当前班组",
                        style = MaterialTheme.typography.bodyLarge.copy(color = onSv)
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
                TeamDropdown(
                    selectedTeamId = selectedTeamId,
                    availableTeams = availableTeams,
                    onTeamSelected = onTeamSelected
                )
            }
        }

        // Menu card
        Card(
            shape = V2CardShape,
            colors = CardDefaults.cardColors(containerColor = surface)
        ) {
            Column {
                ProfileMenuItem(
                    icon = Icons.Filled.Settings,
                    title = "倒班规则",
                    subtitle = "自定义周期、班次和默认班组",
                    onBg = onBg, onSv = onSv,
                    onClick = onRulesClick
                )
                ProfileMenuDivider(onSv = onSv)
                ProfileMenuItem(
                    icon = Icons.Filled.Notifications,
                    title = "提醒设置",
                    subtitle = "为每个班次设置提醒时间",
                    onBg = onBg, onSv = onSv,
                    onClick = onAlarmClick
                )
            }
        }

        // About card
        Card(
            shape = V2CardShape,
            colors = CardDefaults.cardColors(containerColor = surface)
        ) {
            Column {
                ProfileMenuItem(
                    icon = Icons.Filled.Star,
                    title = "给个好评",
                    subtitle = "去应用商店为我们评分",
                    onBg = onBg, onSv = onSv,
                    onClick = { /* TODO */ }
                )
                ProfileMenuDivider(onSv = onSv)
                ProfileMenuItem(
                    icon = Icons.Filled.Info,
                    title = "关于",
                    subtitle = "倒班助手 v1.0",
                    onBg = onBg, onSv = onSv,
                    onClick = { /* TODO */ }
                )
            }
        }
    }
}

@Composable
private fun ProfileMenuDivider(onSv: androidx.compose.ui.graphics.Color = MaterialTheme.colorScheme.onSurfaceVariant) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 56.dp)
            .height(1.dp)
            .background(onSv.copy(alpha = 0.15f))
    )
}

@Composable
private fun ProfileMenuItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    onBg: androidx.compose.ui.graphics.Color,
    onSv: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = onBg,
            modifier = Modifier.size(24.dp)
        )
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge.copy(
                    color = onBg,
                    fontWeight = FontWeight.Medium
                )
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
            )
        }
        Icon(
            imageVector = Icons.Filled.ChevronRight,
            contentDescription = null,
            tint = onSv,
            modifier = Modifier.size(20.dp)
        )
    }
}
