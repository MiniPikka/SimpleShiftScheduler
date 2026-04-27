package com.simpleshift.scheduler.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.viewmodel.SettingsUiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    uiState: SettingsUiState,
    onUpdateCycleLength: (Int) -> Unit,
    onSetDayShift: (Int, ShiftType) -> Unit,
    onSelectDefaultTeam: (Int) -> Unit,
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
                    TextButton(onClick = {
                        if (uiState.isDirty) showDiscardDialog = true
                        else onNavigateBack()
                    }) {
                        Text("← 返回")
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
    val shiftLabel = shiftTypeToLabel(shiftType)

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
                    text = { Text(shiftTypeToLabel(type)) },
                    onClick = {
                        expanded = false
                        onShiftSelected(type)
                    }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TeamDropdown(
    selectedTeamId: Int,
    availableTeams: List<com.simpleshift.scheduler.domain.model.Team>,
    onTeamSelected: (Int) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val selectedTeam = availableTeams.find { it.id == selectedTeamId }
        ?: availableTeams.first()

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it }
    ) {
        OutlinedTextField(
            value = selectedTeam.name,
            onValueChange = {},
            readOnly = true,
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier.menuAnchor().fillMaxWidth()
        )
        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            availableTeams.forEach { team ->
                DropdownMenuItem(
                    text = { Text(team.name) },
                    onClick = {
                        expanded = false
                        onTeamSelected(team.id)
                    }
                )
            }
        }
    }
}

private fun shiftTypeToLabel(shiftType: ShiftType): String {
    return when (shiftType) {
        ShiftType.MORNING -> "早"
        ShiftType.AFTERNOON -> "中"
        ShiftType.REST -> "休"
        ShiftType.NIGHT -> "夜"
        ShiftType.STUDY -> "学"
    }
}
