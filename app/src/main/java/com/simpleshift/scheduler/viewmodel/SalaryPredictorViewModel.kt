package com.simpleshift.scheduler.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import androidx.compose.runtime.Immutable
import com.simpleshift.scheduler.data.repository.SettingsRepository
import com.simpleshift.scheduler.domain.calculateSalaryBreakdown
import com.simpleshift.scheduler.domain.countAllShiftTypesInMonth
import com.simpleshift.scheduler.domain.simulateExtraShifts
import com.simpleshift.scheduler.domain.teamPhaseStepFor
import com.simpleshift.scheduler.domain.model.SalaryBreakdown
import com.simpleshift.scheduler.domain.model.SalaryConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.YearMonth

class SalaryPredictorViewModel(
    application: Application,
    private val todayProvider: () -> LocalDate = { LocalDate.now() }
) : AndroidViewModel(application) {

    @Immutable
    data class SalaryPredictorUiState(
        val salaryConfig: SalaryConfig = SalaryConfig(),
        val breakdown: SalaryBreakdown? = null,
        val simulatedBreakdown: SalaryBreakdown? = null,
        val selectedTeamId: Int = 1,
        val currentMonth: YearMonth = YearMonth.now(),
        val extraShiftsCount: Int = 0,
        val extraShiftType: ShiftType = ShiftType.NIGHT,
        val isLoading: Boolean = true,
        val isSettingsExpanded: Boolean = false
    )

    private val _uiState = MutableStateFlow(SalaryPredictorUiState())
    val uiState: StateFlow<SalaryPredictorUiState> = _uiState.asStateFlow()

    private val settingsRepository = SettingsRepository(application)

    private var customCycle: List<ShiftType>? = null
    private var referenceDate: LocalDate? = null

    fun updateConfig(newConfig: SalaryConfig) {
        _uiState.value = _uiState.value.copy(salaryConfig = newConfig)
        viewModelScope.launch {
            settingsRepository.saveSalaryConfig(newConfig)
        }
        recalculate()
    }

    fun setTeam(teamId: Int) {
        _uiState.value = _uiState.value.copy(selectedTeamId = teamId)
        recalculate()
    }

    fun setMonth(yearMonth: YearMonth) {
        _uiState.value = _uiState.value.copy(currentMonth = yearMonth)
        recalculate()
    }

    fun setExtraShiftsCount(count: Int) {
        _uiState.value = _uiState.value.copy(extraShiftsCount = count)
        recomputeSimulation()
    }

    fun setExtraShiftType(type: ShiftType) {
        _uiState.value = _uiState.value.copy(extraShiftType = type)
        recomputeSimulation()
    }

    fun toggleSettingsExpanded() {
        _uiState.value = _uiState.value.copy(
            isSettingsExpanded = !_uiState.value.isSettingsExpanded
        )
    }

    fun refresh(
        customCycle: List<ShiftType>?,
        referenceDate: LocalDate,
        teamId: Int,
        salaryConfig: SalaryConfig
    ) {
        this.customCycle = customCycle
        this.referenceDate = referenceDate

        _uiState.value = _uiState.value.copy(
            selectedTeamId = teamId,
            salaryConfig = salaryConfig
        )
        recalculate()
    }

    private fun recalculate() {
        val state = _uiState.value
        val cycle = customCycle
        val ref = referenceDate ?: return

        val teamPhaseOffset = (state.selectedTeamId - 1) * teamPhaseStepFor(cycle)

        val counts = countAllShiftTypesInMonth(
            yearMonth = state.currentMonth,
            teamPhaseOffset = teamPhaseOffset,
            customCycle = cycle,
            referenceDate = ref
        )

        val breakdown = calculateSalaryBreakdown(state.salaryConfig, counts, state.currentMonth)

        _uiState.value = state.copy(
            breakdown = breakdown,
            isLoading = false
        )

        recomputeSimulation()
    }

    private fun recomputeSimulation() {
        val state = _uiState.value
        val current = state.breakdown ?: return

        val simulated = if (state.extraShiftsCount > 0) {
            simulateExtraShifts(current, state.extraShiftsCount, state.extraShiftType, state.salaryConfig)
        } else null

        _uiState.value = _uiState.value.copy(simulatedBreakdown = simulated)
    }

    @Suppress("unused")
    constructor(application: Application) : this(
        application = application,
        todayProvider = { LocalDate.now() }
    )
}
