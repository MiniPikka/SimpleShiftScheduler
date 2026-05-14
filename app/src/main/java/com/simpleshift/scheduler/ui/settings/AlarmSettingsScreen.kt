package com.simpleshift.scheduler.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
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
                        Icon(imageVector = Icons.Filled.ArrowBack, contentDescription = "返回")
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
        AlarmTimePickerDialog(
            currentTime = alarmTime,
            onConfirm = { time -> onEdit(time); showDialog = false },
            onRemove = { onRemove(); showDialog = false },
            onDismiss = { showDialog = false }
        )
    }
}

@Composable
private fun AlarmTimePickerDialog(
    currentTime: AlarmTime?,
    onConfirm: (AlarmTime) -> Unit,
    onRemove: () -> Unit,
    onDismiss: () -> Unit
) {
    var hour by remember { mutableIntStateOf(currentTime?.hour ?: 7) }
    var minute by remember { mutableIntStateOf(currentTime?.minute ?: 0) }
    var hourText by remember(hour) { mutableStateOf(hour.toString().padStart(2, '0')) }
    var minuteText by remember(minute) { mutableStateOf(minute.toString().padStart(2, '0')) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("设置提醒时间") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    OutlinedTextField(
                        value = hourText,
                        onValueChange = { s ->
                            val digits = s.take(2).filter { it.isDigit() }
                            hourText = digits
                            digits.toIntOrNull()?.let { if (it in 0..23) hour = it }
                        },
                        label = { Text("时") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        singleLine = true,
                        modifier = Modifier.width(72.dp),
                        textStyle = MaterialTheme.typography.headlineSmall
                    )
                    Text(" : ", style = MaterialTheme.typography.headlineSmall)
                    OutlinedTextField(
                        value = minuteText,
                        onValueChange = { s ->
                            val digits = s.take(2).filter { it.isDigit() }
                            minuteText = digits
                            digits.toIntOrNull()?.let { if (it in 0..59) minute = it }
                        },
                        label = { Text("分") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        singleLine = true,
                        modifier = Modifier.width(72.dp),
                        textStyle = MaterialTheme.typography.headlineSmall
                    )
                }

                if (currentTime != null) {
                    Spacer(Modifier.height(16.dp))
                    TextButton(onClick = onRemove) {
                        Text("关闭此班次提醒", color = MaterialTheme.colorScheme.error)
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(AlarmTime(hour, minute)) }) { Text("确定") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("取消") }
        }
    )
}
