package com.simpleshift.scheduler.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.ShiftType

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlarmSettingsScreen(
    alarmSettings: com.simpleshift.scheduler.domain.model.AlarmSettings,
    onUpdateAlarmTime: (ShiftType, AlarmTime?) -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("提醒设置") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Spacer(modifier = Modifier.height(8.dp))

            // Info card explaining how reminders work
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                )
            ) {
                Row(
                    modifier = Modifier.padding(12.dp),
                    verticalAlignment = androidx.compose.ui.Alignment.Top
                ) {
                    Icon(
                        imageVector = Icons.Filled.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "关于提醒",
                            style = MaterialTheme.typography.bodyLarge.copy(
                                color = MaterialTheme.colorScheme.onBackground
                            )
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "设置提醒后，倒班助手会在系统日历中创建日程并在指定时间弹出通知。" +
                                "日程持久化在系统日历数据库，重启手机不会丢失。" +
                                "夜班提醒将自动提前到前一天（适配夜班车次）。" +
                                "每次修改设置后自动同步未来一年。无需联网，纯本地运行。" +
                                "提醒方式由系统日历 App 管理，可在日历中调整通知设置。",
                            style = MaterialTheme.typography.bodyMedium.copy(
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        )
                    }
                }
            }

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    ShiftType.entries.forEach { type ->
                        ShiftAlarmRow(
                            shiftType = type,
                            alarmTime = alarmSettings.alarms[type],
                            onEdit = { onUpdateAlarmTime(type, it) },
                            onRemove = { onUpdateAlarmTime(type, null) }
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ShiftAlarmRow(
    shiftType: ShiftType,
    alarmTime: AlarmTime?,
    onEdit: (AlarmTime) -> Unit,
    onRemove: () -> Unit
) {
    val label = com.simpleshift.scheduler.util.ShiftLabelMapper.toLabel(shiftType)
    var showDialog by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text("${label}班", style = MaterialTheme.typography.bodyLarge)
        TextButton(onClick = { showDialog = true }) {
            Text(
                if (alarmTime != null) {
                    "${alarmTime.hour.toString().padStart(2, '0')}:${alarmTime.minute.toString().padStart(2, '0')}"
                } else {
                    "未设置"
                }
            )
        }
    }

    if (showDialog) {
        val state = rememberTimePickerState(
            initialHour = alarmTime?.hour ?: 7,
            initialMinute = alarmTime?.minute ?: 0,
            is24Hour = true
        )

        AlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text("${label}班 提醒时间") },
            text = {
                TimePicker(state = state)
            },
            confirmButton = {
                TextButton(onClick = {
                    onEdit(AlarmTime(state.hour, state.minute))
                    showDialog = false
                }) { Text("确定") }
            },
            dismissButton = {
                Row {
                    if (alarmTime != null) {
                        TextButton(onClick = {
                            onRemove()
                            showDialog = false
                        }) {
                            Text("关闭提醒", color = MaterialTheme.colorScheme.error)
                        }
                    }
                    TextButton(onClick = { showDialog = false }) { Text("取消") }
                }
            }
        )
    }
}
