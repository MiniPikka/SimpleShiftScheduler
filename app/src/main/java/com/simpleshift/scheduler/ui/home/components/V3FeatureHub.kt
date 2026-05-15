package com.simpleshift.scheduler.ui.home.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.People
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.ui.theme.V2CardShape

@Composable
fun V3FeatureHub(
    onLeaveOptimizerClick: () -> Unit,
    onColleagueModeClick: () -> Unit,
    onSalaryPredictorClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val primary = MaterialTheme.colorScheme.primary
    val onSv = MaterialTheme.colorScheme.onSurfaceVariant
    val surface = MaterialTheme.colorScheme.surface

    AnimatedVisibility(
        visible = true,
        enter = fadeIn() + slideInVertically { it / 3 },
        modifier = modifier
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            FeatureHubCard(
                icon = { Icon(Icons.Filled.CalendarMonth, null, tint = primary, modifier = Modifier.size(24.dp)) },
                title = "拼假神器",
                subtitle = "请最少假·连休最久",
                surface = surface, onSv = onSv,
                onClick = onLeaveOptimizerClick,
                modifier = Modifier.weight(1f)
            )
            FeatureHubCard(
                icon = { Icon(Icons.Filled.People, null, tint = primary, modifier = Modifier.size(24.dp)) },
                title = "同事模式",
                subtitle = "两人何时共同休息",
                surface = surface, onSv = onSv,
                onClick = onColleagueModeClick,
                modifier = Modifier.weight(1f)
            )
            FeatureHubCard(
                icon = { Icon(Icons.Filled.AttachMoney, null, tint = primary, modifier = Modifier.size(24.dp)) },
                title = "倒班津贴",
                subtitle = "本月能拿多少补贴",
                surface = surface, onSv = onSv,
                onClick = onSalaryPredictorClick,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun FeatureHubCard(
    icon: @Composable () -> Unit,
    title: String,
    subtitle: String,
    surface: androidx.compose.ui.graphics.Color,
    onSv: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = V2CardShape,
        color = surface,
        modifier = modifier.clickable(onClick = onClick)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            icon()
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium.copy(
                    fontSize = MaterialTheme.typography.bodyMedium.fontSize * 0.85f,
                    color = onSv
                ),
                textAlign = TextAlign.Center
            )
        }
    }
}
