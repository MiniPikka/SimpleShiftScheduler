package com.simpleshift.scheduler.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.simpleshift.scheduler.domain.getShiftInfo
import com.simpleshift.scheduler.domain.teamPhaseStepFor
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

data class HomeUiState(
    val todayDate: String = "",
    val shiftType: ShiftType = ShiftType.REST,
    val shiftLabel: String = "",
    val dayOfCycle: Int = 1,
    val totalDays: Int = ShiftCycleConfig.CYCLE_LENGTH,
    val selectedTeamId: Int = 1,
    val availableTeams: List<Team> = Team.ALL_TEAMS
)

class HomeViewModel(
    application: Application,
    private val currentDateProvider: () -> LocalDate = { LocalDate.now() },
    private val localeProvider: () -> Locale = { Locale.getDefault() }
) : AndroidViewModel(application) {

    // Secondary constructor for Android ViewModelProvider
    constructor(application: Application) : this(
        application = application,
        currentDateProvider = { LocalDate.now() },
        localeProvider = { Locale.getDefault() }
    )

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    var customCycle: List<ShiftType>? = null

    init {
        refreshToday()
    }

    fun selectTeam(teamId: Int) {
        _uiState.value = _uiState.value.copy(selectedTeamId = teamId)
        refreshToday()
    }

    fun refreshToday() {
        val today = currentDateProvider()
        val teamPhaseOffset = (_uiState.value.selectedTeamId - 1) * teamPhaseStepFor(customCycle)
        val shiftInfo = getShiftInfo(today, teamPhaseOffset, customCycle)
        val totalDays = customCycle?.size ?: ShiftCycleConfig.CYCLE_LENGTH
        val dateFormatter = DateTimeFormatter
            .ofLocalizedDate(FormatStyle.FULL)
            .withLocale(localeProvider())
        _uiState.value = _uiState.value.copy(
            todayDate = today.format(dateFormatter),
            shiftType = shiftInfo.shiftType,
            shiftLabel = mapShiftLabel(shiftInfo.shiftType),
            dayOfCycle = shiftInfo.dayOfCycle,
            totalDays = totalDays
        )
    }

    private fun mapShiftLabel(shiftType: ShiftType): String =
        com.simpleshift.scheduler.util.ShiftLabelMapper.toLabel(shiftType)
}
