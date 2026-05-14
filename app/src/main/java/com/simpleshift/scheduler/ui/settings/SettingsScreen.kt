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
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.ui.common.TeamDropdown
import com.simpleshift.scheduler.viewmodel.SettingsUiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    uiState: SettingsUiState,
    onUpdateCycleLength: (Int) -> Unit,
    onSetDayShift: (Int, ShiftType) -> Unit,
    onSelectDefaultTeam: (Int) -> Unit,
    onUpdateAlarmTime: (ShiftType, AlarmTime?) -> Unit = { _, _ -> },
    onSave: () -> Unit,
    onCancel: () -> Unit,
    onNavigateBack: () -> Unit
) {
    var showDiscardDialog by remember { mutableStateOf(false) }
    var cycleLengthText by remember(uiState.cycleLength) { mutableStateOf(uiState.cycleLength.toString()) }

    if (showDiscardDialog) {
        AlertDialog(
            onDismissRequest = { showDiscardDialog = false },
            title = { Text("放弃更改？") },
            text = { Text("有未保存的修改，确定要返回吗？") },
            confirmButton = {
                TextButton(onClick = {
                    showDiscardDialog = false
                    onCancel()
                    onNavigateBack()
                }) { Text("确定") }
            },
            dismissButton = {
                TextButton(onClick = { showDiscardDialog = false }) { Text("继续编辑") }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("倒班规则设置") },
                navigationIcon = {
                    IconButton(onClick = {
                        if (uiState.isDirty) showDiscardDialog = true
                        else onNavigateBack()
                    }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "返回"
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = cycleLengthText,
                onValueChange = { text ->
                    val filtered = text.filter { it.isDigit() }
                    cycleLengthText = filtered
                    val parsed = filtered.toIntOrNull()
                    if (parsed != null && parsed > 0) {
                        onUpdateCycleLength(parsed)
                    }
                },
                label = { Text("周期长度") },
                suffix = { Text("天") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )

            Text(
                text = "每天班次（共 ${uiState.shiftCycle.size} 天）",
                style = MaterialTheme.typography.titleSmall
            )

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
            ) {
                LazyVerticalGrid(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(8.dp),
                    columns = GridCells.Fixed(4),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    itemsIndexed(uiState.shiftCycle) { index, shiftType ->
                        ShiftDayPickerCell(
                            dayNumber = index + 1,
                            shiftType = shiftType,
                            onShiftSelected = { onSetDayShift(index, it) }
                        )
                    }
                }
            }

            Text(
                text = "默认班组",
                style = MaterialTheme.typography.titleSmall
            )

            TeamDropdown(
                selectedTeamId = uiState.defaultTeamId,
                availableTeams = uiState.availableTeams,
                onTeamSelected = onSelectDefaultTeam
            )

            Text(
                text = "提醒设置",
                style = MaterialTheme.typography.titleSmall
            )

            Card(modifier = Modifier.fillMaxWidth()) {
                Column(
                    modifier = Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    ShiftType.entries.forEach { type ->
                        ShiftAlarmRow(
                            shiftType = type,
                            alarmTime = uiState.alarmSettings.alarms[type],
                            onEdit = { onUpdateAlarmTime(type, it) },
                            onRemove = { onUpdateAlarmTime(type, null) }
                        )
                    }
                }
            }

            if (uiState.isSaved) {
                Text(
                    text = "设置已保存",
                    color = MaterialTheme.colorScheme.primary,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Button(
                    onClick = onSave,
                    modifier = Modifier.weight(1f),
                    enabled = uiState.isDirty
                ) {
                    Text("保存")
                }
                OutlinedButton(
                    onClick = onCancel,
                    modifier = Modifier.weight(1f),
                    enabled = uiState.isDirty
                ) {
                    Text("取消")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ShiftDayPickerCell(
    dayNumber: Int,
    shiftType: ShiftType,
    onShiftSelected: (ShiftType) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val shiftLabel = com.simpleshift.scheduler.util.ShiftLabelMapper.toLabel(shiftType)

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it }
    ) {
        OutlinedTextField(
            value = shiftLabel,
            onValueChange = {},
            readOnly = true,
            label = { Text("第${dayNumber}天", fontSize = 10.sp) },
            textStyle = MaterialTheme.typography.bodySmall,
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier.menuAnchor()
        )
        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            ShiftType.entries.forEach { type ->
                DropdownMenuItem(
                    text = { Text(com.simpleshift.scheduler.util.ShiftLabelMapper.toLabel(type)) },
                    onClick = {
                        expanded = false
                        onShiftSelected(type)
                    }
                )
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
                        Text(
                            "关闭此班次提醒",
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(AlarmTime(hour, minute)) }) {
                Text("确定")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("取消") }
        }
    )
}
