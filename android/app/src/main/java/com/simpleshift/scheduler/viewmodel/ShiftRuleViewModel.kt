package com.simpleshift.scheduler.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.compose.runtime.Immutable
import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDate

@Immutable
data class ShiftRuleUiState(
    val step: Int = 1,
    val rotationSequence: List<ShiftType> = emptyList(),
    val startDate: LocalDate = LocalDate.now(),
    val hasEndDate: Boolean = false,
    val endDate: LocalDate? = null,
    val defaultTeamId: Int = 1,
    val availableTeams: List<Team> = Team.ALL_TEAMS,
    val isSaved: Boolean = false
)

class ShiftRuleViewModel(
    application: Application,
    initialSettings: RuntimeShiftSettings = RuntimeShiftSettings(),
    private val onSettingsSaved: (RuntimeShiftSettings) -> Unit = {}
) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(
        ShiftRuleUiState(
            rotationSequence = initialSettings.shiftCycle,
            startDate = initialSettings.referenceDate,
            defaultTeamId = initialSettings.defaultTeamId
        )
    )
    val uiState: StateFlow<ShiftRuleUiState> = _uiState.asStateFlow()

    fun addToSequence(type: ShiftType) {
        val current = _uiState.value
        if (current.rotationSequence.size >= 100) return
        _uiState.value = current.copy(
            rotationSequence = current.rotationSequence + type,
            isSaved = false
        )
    }

    fun removeFromSequence(index: Int) {
        val current = _uiState.value
        if (index < 0 || index >= current.rotationSequence.size) return
        _uiState.value = current.copy(
            rotationSequence = current.rotationSequence.toMutableList().also { it.removeAt(index) },
            isSaved = false
        )
    }

    fun goToStep2() {
        val current = _uiState.value
        if (current.rotationSequence.isEmpty()) return
        _uiState.value = current.copy(step = 2)
    }

    fun goBackToStep1() {
        _uiState.value = _uiState.value.copy(step = 1)
    }

    fun setStartDate(date: LocalDate) {
        _uiState.value = _uiState.value.copy(startDate = date, isSaved = false)
    }

    fun setHasEndDate(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(
            hasEndDate = enabled,
            endDate = if (!enabled) null else _uiState.value.endDate,
            isSaved = false
        )
    }

    fun setEndDate(date: LocalDate?) {
        _uiState.value = _uiState.value.copy(endDate = date, isSaved = false)
    }

    fun setDefaultTeam(teamId: Int) {
        _uiState.value = _uiState.value.copy(defaultTeamId = teamId, isSaved = false)
    }

    fun save() {
        val current = _uiState.value
        val settings = RuntimeShiftSettings(
            cycleLength = current.rotationSequence.size,
            shiftCycle = current.rotationSequence,
            defaultTeamId = current.defaultTeamId,
            referenceDate = current.startDate
        )
        onSettingsSaved(settings)
        _uiState.value = current.copy(isSaved = true)
    }
}
