package com.simpleshift.scheduler.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
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
