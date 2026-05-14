package com.simpleshift.scheduler.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.simpleshift.scheduler.data.repository.SettingsRepository
import com.simpleshift.scheduler.domain.findBestLeavePlans
import com.simpleshift.scheduler.domain.model.LeaveStrategy
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.teamPhaseOffsetFor
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

class LeaveOptimizerViewModel(
    application: Application,
    private val todayProvider: () -> LocalDate = { LocalDate.now() }
) : AndroidViewModel(application) {

    data class LeaveOptimizerUiState(
        val strategies: List<LeaveStrategy> = emptyList(),
        val selectedTeamId: Int = 1,
        val maxLeaveDays: Int = 5,
        val analyzedDays: Int = 365,
        val analyzedDateRange: String = "",
        val isLoading: Boolean = true,
        val errorMessage: String? = null
    )

    private val _uiState = MutableStateFlow(LeaveOptimizerUiState())
    val uiState: StateFlow<LeaveOptimizerUiState> = _uiState.asStateFlow()

    private val settingsRepository = SettingsRepository(application)

    private var customCycle: List<ShiftType>? = null
    private var referenceDate: LocalDate? = null

    /**
     * Refreshes the leave strategy analysis with current settings.
     * Called from MainActivity when the page loads or settings change.
     */
    fun refresh(
        customCycle: List<ShiftType>?,
        referenceDate: LocalDate,
        teamId: Int
    ) {
        this.customCycle = customCycle
        this.referenceDate = referenceDate

        val today = todayProvider()
        val endOfYear = LocalDate.of(today.year, 12, 31)
        val daysToAnalyze = ChronoUnit.DAYS.between(today, endOfYear).toInt() + 1
        val phaseOffset = teamPhaseOffsetFor(teamId, customCycle)

        val strategies = try {
            findBestLeavePlans(
                today = today,
                daysToAnalyze = daysToAnalyze,
                teamPhaseOffset = phaseOffset,
                customCycle = customCycle,
                referenceDate = referenceDate,
                maxLeaveDays = _uiState.value.maxLeaveDays
            )
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                errorMessage = "分析失败: ${e.localizedMessage ?: "未知错误"}"
            )
            return
        }

        // Format: "2026/05/14 — 12/31" — year shown once, no ambiguity
        val range = "${today.format(DateTimeFormatter.ofPattern("yyyy/MM/dd"))} — ${endOfYear.format(DateTimeFormatter.ofPattern("MM/dd"))}"

        _uiState.value = _uiState.value.copy(
            strategies = strategies,
            selectedTeamId = teamId,
            analyzedDays = daysToAnalyze,
            analyzedDateRange = range,
            isLoading = false,
            errorMessage = null
        )
    }

    fun setMaxLeaveDays(days: Int) {
        _uiState.value = _uiState.value.copy(maxLeaveDays = days, isLoading = true)
        // Re-run analysis with new max
        val cycle = customCycle ?: return
        val ref = referenceDate ?: return
        refresh(cycle, ref, _uiState.value.selectedTeamId)
    }

    // Secondary constructor for Android ViewModelProvider reflection
    @Suppress("unused")
    constructor(application: Application) : this(
        application = application,
        todayProvider = { LocalDate.now() }
    )
}
