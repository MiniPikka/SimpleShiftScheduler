package com.simpleshift.scheduler.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import com.simpleshift.scheduler.ui.common.TeamDropdown
import com.simpleshift.scheduler.ui.theme.V2CardShape
import com.simpleshift.scheduler.ui.theme.v2ShiftColor
import com.simpleshift.scheduler.util.ShiftLabelMapper
import com.simpleshift.scheduler.viewmodel.ShiftRuleUiState
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShiftRuleEditorScreen(
    uiState: ShiftRuleUiState,
    onAddToSequence: (ShiftType) -> Unit,
    onRemoveFromSequence: (Int) -> Unit,
    onGoToStep2: () -> Unit,
    onGoBackToStep1: () -> Unit,
    onSetStartDate: (LocalDate) -> Unit,
    onSetHasEndDate: (Boolean) -> Unit,
    onSetEndDate: (LocalDate?) -> Unit,
    onSetDefaultTeam: (Int) -> Unit,
    onSave: () -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("倒班规则设置") },
                navigationIcon = {
                    IconButton(onClick = {
                        if (uiState.step == 2) onGoBackToStep1() else onNavigateBack()
                    }) {
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
                .padding(horizontal = 16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Spacer(modifier = Modifier.height(8.dp))

            if (uiState.step == 1) {
                Step1BuildSequence(
                    rotationSequence = uiState.rotationSequence,
                    onAddToSequence = onAddToSequence,
                    onRemoveFromSequence = onRemoveFromSequence,
                    onGoToStep2 = onGoToStep2
                )
            } else {
                Step2SaveSettings(
                    uiState = uiState,
                    onSetStartDate = onSetStartDate,
                    onSetHasEndDate = onSetHasEndDate,
                    onSetEndDate = onSetEndDate,
                    onSetDefaultTeam = onSetDefaultTeam,
                    onSave = onSave
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
private fun Step1BuildSequence(
    rotationSequence: List<ShiftType>,
    onAddToSequence: (ShiftType) -> Unit,
    onRemoveFromSequence: (Int) -> Unit,
    onGoToStep2: () -> Unit
) {
    // Instruction
    Text(
        text = "点击下方按钮，按顺序构建倒班序列：",
        style = MaterialTheme.typography.bodyMedium
    )

    // 5 shift type buttons
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        ShiftType.entries.forEach { type ->
            val color = v2ShiftColor(type)
            FilledTonalButton(
                onClick = { onAddToSequence(type) },
                modifier = Modifier.weight(1f),
                colors = androidx.compose.material3.ButtonDefaults.filledTonalButtonColors(
                    containerColor = color.copy(alpha = 0.2f),
                    contentColor = color
                )
            ) {
                Text(ShiftLabelMapper.toLabel(type), fontWeight = FontWeight.Bold)
            }
        }
    }

    // Sequence display
    Text(
        text = "已构建序列（共 ${rotationSequence.size} 天）",
        style = MaterialTheme.typography.titleSmall
    )

    Card(
        shape = V2CardShape,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        modifier = Modifier.fillMaxWidth()
    ) {
        if (rotationSequence.isEmpty()) {
            Text(
                text = "点击上方按钮开始构建倒班序列",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp)
            )
        } else {
            Column(
                modifier = Modifier.padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Display chips in rows
                val rows = rotationSequence.chunked(6)
                rows.forEachIndexed { rowIdx, rowItems ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        rowItems.forEachIndexed { colIdx, type ->
                            val globalIdx = rowIdx * 6 + colIdx
                            SequenceChip(
                                shiftType = type,
                                dayNumber = globalIdx + 1,
                                onRemove = { onRemoveFromSequence(globalIdx) },
                                modifier = Modifier.weight(1f)
                            )
                        }
                        // Fill remaining slots with empty space
                        repeat(6 - rowItems.size) {
                            Spacer(modifier = Modifier.weight(1f))
                        }
                    }
                }
            }
        }
    }

    Spacer(modifier = Modifier.height(8.dp))

    // Next step button
    Button(
        onClick = onGoToStep2,
        enabled = rotationSequence.isNotEmpty(),
        modifier = Modifier.fillMaxWidth()
    ) {
        Text("下一步")
    }
}

@Composable
private fun SequenceChip(
    shiftType: ShiftType,
    dayNumber: Int,
    onRemove: () -> Unit,
    modifier: Modifier = Modifier
) {
    val accentColor = v2ShiftColor(shiftType)
    Surface(
        shape = V2CardShape,
        color = accentColor.copy(alpha = 0.15f),
        modifier = modifier
    ) {
        Box(modifier = Modifier.padding(start = 10.dp, end = 4.dp, top = 6.dp, bottom = 6.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column {
                    Text(
                        text = "${dayNumber}天",
                        style = MaterialTheme.typography.labelSmall,
                        color = accentColor
                    )
                    Text(
                        text = ShiftLabelMapper.toLabel(shiftType),
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Bold,
                        color = accentColor
                    )
                }
                Spacer(modifier = Modifier.width(4.dp))
                IconButton(
                    onClick = onRemove,
                    modifier = Modifier.size(20.dp)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Close,
                        contentDescription = "删除",
                        tint = Color(0xFFEF4444),
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun Step2SaveSettings(
    uiState: ShiftRuleUiState,
    onSetStartDate: (LocalDate) -> Unit,
    onSetHasEndDate: (Boolean) -> Unit,
    onSetEndDate: (LocalDate?) -> Unit,
    onSetDefaultTeam: (Int) -> Unit,
    onSave: () -> Unit
) {
    var showStartDatePicker by remember { mutableStateOf(false) }
    var showEndDatePicker by remember { mutableStateOf(false) }

    // Start date
    Text("起始日期", style = MaterialTheme.typography.titleSmall)
    OutlinedTextField(
        value = formatDate(uiState.startDate),
        onValueChange = {},
        readOnly = true,
        trailingIcon = { TextButton(onClick = { showStartDatePicker = true }) { Text("选择") } },
        modifier = Modifier.fillMaxWidth(),
        singleLine = true
    )

    if (showStartDatePicker) {
        val pickerState = rememberDatePickerState(
            initialSelectedDateMillis = uiState.startDate.atStartOfDay(ZoneId.systemDefault())
                .toInstant().toEpochMilli()
        )
        DatePickerDialog(
            onDismissRequest = { showStartDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    pickerState.selectedDateMillis?.let { millis ->
                        val date = Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).toLocalDate()
                        onSetStartDate(date)
                    }
                    showStartDatePicker = false
                }) { Text("确定") }
            },
            dismissButton = {
                TextButton(onClick = { showStartDatePicker = false }) { Text("取消") }
            }
        ) {
            DatePicker(state = pickerState)
        }
    }

    // End date toggle
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onSetHasEndDate(!uiState.hasEndDate) }
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(
            shape = MaterialTheme.shapes.small,
            color = if (uiState.hasEndDate) MaterialTheme.colorScheme.primary
                   else MaterialTheme.colorScheme.surfaceVariant,
            modifier = Modifier.size(20.dp)
        ) {
            if (uiState.hasEndDate) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("✓", color = MaterialTheme.colorScheme.onPrimary, style = MaterialTheme.typography.labelSmall)
                }
            }
        }
        Spacer(modifier = Modifier.width(8.dp))
        Text("设置结束日期（可选）", style = MaterialTheme.typography.bodyMedium)
    }

    if (uiState.hasEndDate) {
        OutlinedTextField(
            value = uiState.endDate?.let { formatDate(it) } ?: "",
            onValueChange = {},
            readOnly = true,
            trailingIcon = { TextButton(onClick = { showEndDatePicker = true }) { Text("选择") } },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            placeholder = { Text("选择日历同步截止日期") }
        )

        if (showEndDatePicker) {
            val endPickerState = rememberDatePickerState(
                initialSelectedDateMillis = uiState.endDate?.atStartOfDay(ZoneId.systemDefault())
                    ?.toInstant()?.toEpochMilli()
            )
            DatePickerDialog(
                onDismissRequest = { showEndDatePicker = false },
                confirmButton = {
                    TextButton(onClick = {
                        endPickerState.selectedDateMillis?.let { millis ->
                            val date = Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).toLocalDate()
                            onSetEndDate(date)
                        }
                        showEndDatePicker = false
                    }) { Text("确定") }
                },
                dismissButton = {
                    TextButton(onClick = { showEndDatePicker = false }) { Text("取消") }
                }
            ) {
                DatePicker(state = endPickerState)
            }
        }
    }

    // Default team
    Text("默认班组", style = MaterialTheme.typography.titleSmall)
    TeamDropdown(
        selectedTeamId = uiState.defaultTeamId,
        availableTeams = uiState.availableTeams,
        onTeamSelected = onSetDefaultTeam
    )

    // Sequence preview
    Card(
        shape = V2CardShape,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = "排班预览",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(8.dp))
            val preview = uiState.rotationSequence.take(15).joinToString(" → ") { ShiftLabelMapper.toLabel(it) }
            Text(
                text = if (uiState.rotationSequence.size > 15) "$preview → ..." else preview,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "周期长度: ${uiState.rotationSequence.size} 天 · 起始: ${formatDate(uiState.startDate)}",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }

    // Save button
    Button(
        onClick = onSave,
        modifier = Modifier.fillMaxWidth(),
        enabled = uiState.rotationSequence.isNotEmpty()
    ) {
        Text("保存并生成排班表")
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
}

private fun formatDate(date: LocalDate): String {
    return "${date.year}年${date.monthValue}月${date.dayOfMonth}日"
}
