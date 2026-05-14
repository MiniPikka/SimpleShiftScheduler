package com.simpleshift.scheduler.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.simpleshift.scheduler.domain.generateMonthCalendarDays
import com.simpleshift.scheduler.domain.teamPhaseStepFor
import com.simpleshift.scheduler.domain.model.MonthlyStats
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.util.Locale

data class CalendarDayUiState(
    val dateNumber: Int,
    val shiftLabel: String,
    val shiftType: ShiftType,
    val isCurrentMonth: Boolean,
    val isToday: Boolean = false
)

data class CalendarUiState(
    val monthLabel: String = "",
    val weekLabels: List<String> = emptyList(),
    val days: List<CalendarDayUiState> = emptyList(),
    val stats: MonthlyStats? = null,
    val isCurrentMonth: Boolean = true,
    val selectedTeamId: Int = 1
)

class CalendarViewModel(
    application: Application,
    private val localeProvider: () -> Locale = { Locale.getDefault() },
    private val monthProvider: () -> YearMonth = { YearMonth.now() },
    private val todayProvider: () -> LocalDate = { LocalDate.now() }
) : AndroidViewModel(application) {

    // Secondary constructor for Android ViewModelProvider
    constructor(application: Application) : this(
        application = application,
        localeProvider = { Locale.getDefault() },
        monthProvider = { YearMonth.now() },
        todayProvider = { LocalDate.now() }
    )

    private val _uiState = MutableStateFlow(CalendarUiState())
    val uiState: StateFlow<CalendarUiState> = _uiState.asStateFlow()

    private var currentMonth: YearMonth = monthProvider()
    private var selectedTeamId: Int = 1

    var customCycle: List<ShiftType>? = null
    var customReferenceDate: LocalDate? = null

    init {
        refresh()
    }

    fun setTeam(teamId: Int) {
        selectedTeamId = teamId
        refresh()
    }

    fun goToPreviousMonth() {
        currentMonth = currentMonth.minusMonths(1)
        refresh()
    }

    fun goToNextMonth() {
        currentMonth = currentMonth.plusMonths(1)
        refresh()
    }

    fun goToToday() {
        currentMonth = monthProvider()
        refresh()
    }

    fun computeStats() {
        // Toggle: if already showing stats, dismiss; otherwise compute
        if (_uiState.value.stats != null) {
            dismissStats()
            return
        }
        val refDate = customReferenceDate ?: ShiftCycleConfig.REFERENCE_DATE
        val teamPhaseOffset = (selectedTeamId - 1) * teamPhaseStepFor(customCycle)
        val days = generateMonthCalendarDays(
            currentMonth,
            teamPhaseOffset = teamPhaseOffset,
            customCycle = customCycle,
            referenceDate = refDate
        )
        val currentMonthDays = days.filter { it.isCurrentMonth }
        val stats = MonthlyStats(
            morningCount = currentMonthDays.count { it.shiftType == ShiftType.MORNING },
            afternoonCount = currentMonthDays.count { it.shiftType == ShiftType.AFTERNOON },
            restCount = currentMonthDays.count { it.shiftType == ShiftType.REST },
            nightCount = currentMonthDays.count { it.shiftType == ShiftType.NIGHT },
            studyCount = currentMonthDays.count { it.shiftType == ShiftType.STUDY }
        )
        _uiState.value = _uiState.value.copy(stats = stats)
    }

    fun dismissStats() {
        _uiState.value = _uiState.value.copy(stats = null)
    }

    fun refresh() {
        val locale = localeProvider()
        val monthFormatter = DateTimeFormatter.ofPattern("yyyy年M月", locale)
        val weekLabels = listOf("日", "一", "二", "三", "四", "五", "六")
        val refDate = customReferenceDate ?: ShiftCycleConfig.REFERENCE_DATE
        val teamPhaseOffset = (selectedTeamId - 1) * teamPhaseStepFor(customCycle)

        val days = generateMonthCalendarDays(
            currentMonth,
            teamPhaseOffset = teamPhaseOffset,
            customCycle = customCycle,
            referenceDate = refDate
        )
            .map { day ->
                CalendarDayUiState(
                    dateNumber = day.date.dayOfMonth,
                    shiftLabel = com.simpleshift.scheduler.util.ShiftLabelMapper.toLabel(day.shiftType),
                    shiftType = day.shiftType,
                    isCurrentMonth = day.isCurrentMonth,
                    isToday = day.date == todayProvider()
                )
            }

        _uiState.value = _uiState.value.copy(
            monthLabel = currentMonth.format(monthFormatter),
            weekLabels = weekLabels,
            days = days,
            stats = null,
            isCurrentMonth = currentMonth == monthProvider(),
            selectedTeamId = selectedTeamId
        )
    }

}
