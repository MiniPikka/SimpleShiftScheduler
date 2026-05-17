package com.simpleshift.scheduler.ui.salary_predictor

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.slideInVertically
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import com.simpleshift.scheduler.ui.theme.V2CardShape
import com.simpleshift.scheduler.ui.theme.v2ShiftColor
import com.simpleshift.scheduler.viewmodel.SalaryPredictorViewModel
import java.text.NumberFormat
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SalaryPredictorScreen(
    uiState: SalaryPredictorViewModel.SalaryPredictorUiState,
    availableTeams: List<Team>,
    onNavigateBack: () -> Unit,
    onConfigUpdate: (Map<ShiftType, Double>) -> Unit,
    onTeamSelected: (Int) -> Unit,
    onMonthChange: (YearMonth) -> Unit,
    onExtraShiftsCountChange: (Int) -> Unit,
    onExtraShiftTypeChange: (ShiftType) -> Unit,
    onToggleSettingsExpanded: () -> Unit,
    modifier: Modifier = Modifier
) {
    val surface = MaterialTheme.colorScheme.surface
    val onBg = MaterialTheme.colorScheme.onBackground
    val onSv = MaterialTheme.colorScheme.onSurfaceVariant
    val primary = MaterialTheme.colorScheme.primary

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("倒班津贴") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        },
        modifier = modifier
    ) { paddingValues ->
        if (uiState.isLoading && uiState.breakdown == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = primary)
            }
            return@Scaffold
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Collapsible settings section
            SettingsSection(
                config = uiState.salaryConfig,
                isExpanded = uiState.isSettingsExpanded,
                onToggle = onToggleSettingsExpanded,
                onUpdate = onConfigUpdate,
                surface = surface,
                onBg = onBg,
                onSv = onSv
            )

            // Month + Team selector
            MonthTeamRow(
                currentMonth = uiState.currentMonth,
                selectedTeamId = uiState.selectedTeamId,
                availableTeams = availableTeams,
                onMonthChange = onMonthChange,
                onTeamSelected = onTeamSelected,
                onBg = onBg,
                onSv = onSv
            )

            // Premium total card
            uiState.breakdown?.let { breakdown ->
                PremiumTotalCard(
                    total = breakdown.shiftPremiumTotal,
                    onSv = onSv,
                    primary = primary
                )

                // Shift count breakdown
                ShiftBreakdownSection(
                    breakdown = breakdown,
                    config = uiState.salaryConfig,
                    onBg = onBg,
                    onSv = onSv
                )

                // Simulation card
                SimulationCard(
                    extraCount = uiState.extraShiftsCount,
                    extraShiftType = uiState.extraShiftType,
                    simulatedBreakdown = uiState.simulatedBreakdown,
                    salaryConfig = uiState.salaryConfig,
                    onExtraCountChange = onExtraShiftsCountChange,
                    onExtraShiftTypeChange = onExtraShiftTypeChange,
                    onBg = onBg,
                    primary = primary
                )
            }
        }
    }
}

@Composable
private fun SettingsSection(
    config: com.simpleshift.scheduler.domain.model.SalaryConfig,
    isExpanded: Boolean,
    onToggle: () -> Unit,
    onUpdate: (Map<ShiftType, Double>) -> Unit,
    surface: androidx.compose.ui.graphics.Color,
    onBg: androidx.compose.ui.graphics.Color,
    onSv: androidx.compose.ui.graphics.Color
) {
    val configurableShiftTypes = listOf(ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.NIGHT, ShiftType.STUDY)

    Card(
        shape = V2CardShape,
        colors = CardDefaults.cardColors(containerColor = surface)
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onToggle)
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "津贴设置",
                    style = MaterialTheme.typography.titleMedium.copy(
                        color = onBg,
                        fontWeight = FontWeight.Medium
                    )
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "班次补贴（每班额外金额）",
                        style = MaterialTheme.typography.bodySmall.copy(color = onSv)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        imageVector = Icons.Filled.ArrowDropDown,
                        contentDescription = if (isExpanded) "收起" else "展开",
                        tint = onSv,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            AnimatedVisibility(
                visible = isExpanded,
                enter = expandVertically() + fadeIn(),
                exit = shrinkVertically()
            ) {
                Column(
                    modifier = Modifier.padding(start = 16.dp, end = 16.dp, bottom = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Per-type text editing state — decoupled from parsed Double config
                    // so users can type "5." without it bouncing back to "0"
                    val textValues = remember { mutableStateMapOf<ShiftType, String>() }
                    // Sync config → text when a type hasn't been edited yet
                    configurableShiftTypes.forEach { type ->
                        if (type !in textValues) {
                            textValues[type] = formatPremium(config.shiftPremiums[type] ?: 0.0)
                        }
                    }

                    configurableShiftTypes.chunked(2).forEach { row ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            row.forEach { shiftType ->
                                val label = shiftLabel(shiftType)
                                val accentColor = v2ShiftColor(shiftType)
                                val currentText = textValues[shiftType] ?: "0"

                                Row(
                                    modifier = Modifier.weight(1f),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(8.dp)
                                            .clip(RoundedCornerShape(2.dp))
                                            .background(accentColor)
                                    )
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = label,
                                        style = MaterialTheme.typography.bodyMedium.copy(color = onBg),
                                        modifier = Modifier.width(32.dp)
                                    )
                                    OutlinedTextField(
                                        value = currentText,
                                        onValueChange = { raw ->
                                            val cleaned = cleanDecimalInput(raw)
                                            textValues[shiftType] = cleaned
                                            // Only push to config when a valid number is formed
                                            val parsed = if (cleaned.isEmpty() || cleaned == ".") {
                                                0.0
                                            } else {
                                                cleaned.toDoubleOrNull()
                                            }
                                            if (parsed != null) {
                                                val newMap = config.shiftPremiums.toMutableMap()
                                                newMap[shiftType] = parsed
                                                onUpdate(newMap)
                                            }
                                        },
                                        modifier = Modifier.weight(1f),
                                        singleLine = true,
                                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                                        textStyle = MaterialTheme.typography.bodyMedium.copy(
                                            color = onBg,
                                            textAlign = TextAlign.End
                                        )
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = "元",
                                        style = MaterialTheme.typography.bodySmall.copy(color = onSv)
                                    )
                                }
                            }
                            // Fill empty space if odd number
                            if (row.size < 2) {
                                Spacer(modifier = Modifier.weight(1f))
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MonthTeamRow(
    currentMonth: YearMonth,
    selectedTeamId: Int,
    availableTeams: List<Team>,
    onMonthChange: (YearMonth) -> Unit,
    onTeamSelected: (Int) -> Unit,
    onBg: androidx.compose.ui.graphics.Color,
    onSv: androidx.compose.ui.graphics.Color
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Month switcher
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = { onMonthChange(currentMonth.minusMonths(1)) }) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                    contentDescription = "上月",
                    tint = onBg
                )
            }
            Text(
                text = currentMonth.format(DateTimeFormatter.ofPattern("yyyy年M月")),
                style = MaterialTheme.typography.titleMedium.copy(
                    color = onBg,
                    fontWeight = FontWeight.Medium
                )
            )
            IconButton(onClick = { onMonthChange(currentMonth.plusMonths(1)) }) {
                Icon(
                    Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = "下月",
                    tint = onBg
                )
            }
        }

        // Team selector
        var teamExpanded by remember { mutableStateOf(false) }
        val selectedTeam = availableTeams.find { it.id == selectedTeamId } ?: availableTeams.first()

        Box {
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .clickable { teamExpanded = true }
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = selectedTeam.name,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        color = onBg,
                        fontWeight = FontWeight.Medium
                    )
                )
                Icon(
                    Icons.Filled.ArrowDropDown,
                    contentDescription = null,
                    tint = onSv
                )
            }
            DropdownMenu(
                expanded = teamExpanded,
                onDismissRequest = { teamExpanded = false }
            ) {
                availableTeams.forEach { team ->
                    DropdownMenuItem(
                        text = { Text(team.name) },
                        onClick = {
                            onTeamSelected(team.id)
                            teamExpanded = false
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun PremiumTotalCard(
    total: Double,
    onSv: androidx.compose.ui.graphics.Color,
    primary: androidx.compose.ui.graphics.Color
) {
    val formattedTotal = NumberFormat.getNumberInstance(Locale.getDefault()).format(total)

    Card(
        shape = V2CardShape,
        colors = CardDefaults.cardColors(
            containerColor = primary.copy(alpha = 0.08f)
        ),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "本月倒班津贴",
                style = MaterialTheme.typography.bodyMedium.copy(color = onSv)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "¥$formattedTotal",
                style = MaterialTheme.typography.displaySmall.copy(
                    color = primary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 36.sp
                )
            )
        }
    }
}

@Composable
private fun ShiftBreakdownSection(
    breakdown: com.simpleshift.scheduler.domain.model.SalaryBreakdown,
    config: com.simpleshift.scheduler.domain.model.SalaryConfig,
    onBg: androidx.compose.ui.graphics.Color,
    onSv: androidx.compose.ui.graphics.Color
) {
    Card(
        shape = V2CardShape,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "班次统计",
                style = MaterialTheme.typography.titleSmall.copy(
                    color = onBg,
                    fontWeight = FontWeight.Medium
                )
            )

            // Shift count tags row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                ShiftType.entries.forEach { type ->
                    val count = breakdown.shiftCounts[type] ?: 0
                    val color = v2ShiftColor(type)

                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(color.copy(alpha = 0.12f))
                            .padding(horizontal = 10.dp, vertical = 6.dp)
                    ) {
                        Text(
                            text = "${shiftLabel(type)} ${count}次",
                            style = MaterialTheme.typography.bodySmall.copy(
                                color = color,
                                fontWeight = FontWeight.Medium
                            )
                        )
                    }
                }
            }

            // Contribution details
            val premiumDetails = ShiftType.entries
                .filter { (config.shiftPremiums[it] ?: 0.0) > 0.0 && (breakdown.shiftCounts[it] ?: 0) > 0 }
                .map { type ->
                    val premium = config.shiftPremiums[type] ?: 0.0
                    val count = breakdown.shiftCounts[type] ?: 0
                    val subtotal = premium * count
                    Triple(type, count, subtotal)
                }

            if (premiumDetails.isNotEmpty()) {
                val formatted = premiumDetails.joinToString(" · ") { (type, count, subtotal) ->
                    val amount = NumberFormat.getNumberInstance(Locale.getDefault()).format(subtotal)
                    "${shiftLabel(type)} ${count}次 × ¥${config.shiftPremiums[type]} = ¥$amount"
                }
                Text(
                    text = formatted,
                    style = MaterialTheme.typography.bodySmall.copy(color = onSv)
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SimulationCard(
    extraCount: Int,
    extraShiftType: ShiftType,
    simulatedBreakdown: com.simpleshift.scheduler.domain.model.SalaryBreakdown?,
    salaryConfig: com.simpleshift.scheduler.domain.model.SalaryConfig,
    onExtraCountChange: (Int) -> Unit,
    onExtraShiftTypeChange: (ShiftType) -> Unit,
    onBg: androidx.compose.ui.graphics.Color,
    primary: androidx.compose.ui.graphics.Color
) {
    val premiumTypes = listOf(ShiftType.MORNING, ShiftType.AFTERNOON, ShiftType.NIGHT, ShiftType.STUDY)
    var typeExpanded by remember { mutableStateOf(false) }
    val accentColor = v2ShiftColor(extraShiftType)

    Card(
        shape = V2CardShape,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "假设分析",
                style = MaterialTheme.typography.titleSmall.copy(
                    color = onBg,
                    fontWeight = FontWeight.Medium
                )
            )

            // Extra shift count selector
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "如果多上",
                    style = MaterialTheme.typography.bodyMedium.copy(color = onBg)
                )

                // Count chips
                (0..5).forEach { n ->
                    FilterChip(
                        selected = extraCount == n,
                        onClick = { onExtraCountChange(n) },
                        label = {
                            Text(
                                text = if (n == 0) "0" else "$n",
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    )
                }

                Text(
                    text = "天",
                    style = MaterialTheme.typography.bodyMedium.copy(color = onBg)
                )
            }

            // Shift type selector
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "班次类型：",
                    style = MaterialTheme.typography.bodyMedium.copy(color = onBg)
                )
                Box {
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .border(1.dp, accentColor.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
                            .clickable { typeExpanded = true }
                            .padding(horizontal = 12.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = shiftLabel(extraShiftType),
                            style = MaterialTheme.typography.bodyMedium.copy(
                                color = accentColor,
                                fontWeight = FontWeight.Medium
                            )
                        )
                        Icon(
                            Icons.Filled.ArrowDropDown,
                            contentDescription = null,
                            tint = accentColor
                        )
                    }
                    DropdownMenu(
                        expanded = typeExpanded,
                        onDismissRequest = { typeExpanded = false }
                    ) {
                        premiumTypes.forEach { type ->
                            DropdownMenuItem(
                                text = { Text(shiftLabel(type)) },
                                onClick = {
                                    onExtraShiftTypeChange(type)
                                    typeExpanded = false
                                }
                            )
                        }
                    }
                }
            }

            // Result
            if (extraCount > 0 && simulatedBreakdown != null) {
                val extraAmount = (salaryConfig.shiftPremiums[extraShiftType] ?: 0.0) * extraCount
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(primary.copy(alpha = 0.06f))
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "→ 津贴 +¥${NumberFormat.getNumberInstance(Locale.getDefault()).format(extraAmount)}",
                        style = MaterialTheme.typography.titleMedium.copy(
                            color = primary,
                            fontWeight = FontWeight.Bold
                        )
                    )
                }
            }
        }
    }
}

private fun shiftLabel(type: ShiftType): String = when (type) {
    ShiftType.MORNING -> "早班"
    ShiftType.AFTERNOON -> "中班"
    ShiftType.NIGHT -> "夜班"
    ShiftType.REST -> "休班"
    ShiftType.STUDY -> "学班"
}

private fun formatPremium(value: Double): String {
    return if (value == value.toLong().toDouble()) {
        value.toLong().toString()
    } else {
        value.toString()
    }
}

private fun cleanDecimalInput(input: String): String {
    val allowed = input.filter { it.isDigit() || it == '.' }
    val firstDot = allowed.indexOf('.')
    return if (firstDot == -1) {
        allowed.take(6)
    } else {
        val before = allowed.substring(0, firstDot)
        val after = allowed.substring(firstDot + 1).filter { it.isDigit() }.take(2)
        before.take(4) + "." + after
    }
}
