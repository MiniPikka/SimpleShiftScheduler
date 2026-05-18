package com.simpleshift.scheduler.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.simpleshift.scheduler.domain.getShiftInfo
import com.simpleshift.scheduler.domain.teamPhaseStepFor
import com.simpleshift.scheduler.domain.consecutiveWorkDays
import com.simpleshift.scheduler.domain.countShiftTypeInMonth
import com.simpleshift.scheduler.domain.countWorkDaysInMonth
import com.simpleshift.scheduler.domain.daysUntilNextRest
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import androidx.compose.runtime.Immutable
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import com.simpleshift.scheduler.util.TeamNameMapper
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

@Immutable
data class HomeUiState(
    val todayDate: String = "",
    val shiftType: ShiftType = ShiftType.REST,
    val shiftLabel: String = "",
    val dayOfCycle: Int = 1,
    val totalDays: Int = ShiftCycleConfig.CYCLE_LENGTH,
    val selectedTeamId: Int = 1,
    val availableTeams: List<Team> = Team.ALL_TEAMS,
    val teamName: String = "",
    val daysUntilRest: Int = 0,
    val consecutiveWorkDays: Int = 0,
    val monthlyWorkDays: Int = 0,
    val totalDaysInMonth: Int = 0,
    // V2 fields
    val shiftTimeRange: String? = null,
    val monthlyShiftTypeCount: Int = 0,
    val workIntensity: Int = 0
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
    var customReferenceDate: LocalDate? = null
    private var currentAlarmSettings: AlarmSettings = AlarmSettings()

    init {
        refreshToday()
    }

    fun updateAlarmSettings(settings: AlarmSettings) {
        currentAlarmSettings = settings
        refreshToday()
    }

    fun selectTeam(teamId: Int) {
        _uiState.value = _uiState.value.copy(selectedTeamId = teamId)
        refreshToday()
    }

    fun refreshToday() {
        val today = currentDateProvider()
        val refDate = customReferenceDate ?: ShiftCycleConfig.REFERENCE_DATE
        val teamPhaseOffset = (_uiState.value.selectedTeamId - 1) * teamPhaseStepFor(customCycle)
        val shiftInfo = getShiftInfo(today, teamPhaseOffset, customCycle, refDate)
        val totalDays = customCycle?.size ?: ShiftCycleConfig.CYCLE_LENGTH
        val dateFormatter = DateTimeFormatter
            .ofLocalizedDate(FormatStyle.FULL)
            .withLocale(localeProvider())
        val team = _uiState.value.availableTeams.find { it.id == _uiState.value.selectedTeamId }
        val yearMonth = YearMonth.from(today)

        // V2 fields
        val alarmTime = currentAlarmSettings.alarms[shiftInfo.shiftType]
        val shiftTimeRange = alarmTime?.let {
            "${it.hour.toString().padStart(2, '0')}:${it.minute.toString().padStart(2, '0')}"
        }
        val monthlyShiftTypeCount = countShiftTypeInMonth(
            yearMonth, shiftInfo.shiftType, teamPhaseOffset, customCycle, refDate
        )
        val monthlyWorkDays = countWorkDaysInMonth(yearMonth, teamPhaseOffset, customCycle, refDate)
        val workIntensity = if (today.dayOfMonth > 0) {
            monthlyWorkDays * 100 / today.dayOfMonth
        } else 0

        _uiState.value = _uiState.value.copy(
            todayDate = today.format(dateFormatter),
            shiftType = shiftInfo.shiftType,
            shiftLabel = com.simpleshift.scheduler.util.ShiftLabelMapper.toLabel(getApplication(), shiftInfo.shiftType),
            dayOfCycle = shiftInfo.dayOfCycle,
            totalDays = totalDays,
            teamName = TeamNameMapper.toName(_uiState.value.selectedTeamId, getApplication()),
            daysUntilRest = daysUntilNextRest(today, teamPhaseOffset, customCycle, refDate),
            consecutiveWorkDays = consecutiveWorkDays(today, teamPhaseOffset, customCycle, refDate),
            monthlyWorkDays = monthlyWorkDays,
            totalDaysInMonth = yearMonth.lengthOfMonth(),
            shiftTimeRange = shiftTimeRange,
            monthlyShiftTypeCount = monthlyShiftTypeCount,
            workIntensity = workIntensity
        )
    }

}
