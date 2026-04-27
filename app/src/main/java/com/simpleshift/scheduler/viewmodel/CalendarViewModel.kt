package com.simpleshift.scheduler.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.simpleshift.scheduler.R
import com.simpleshift.scheduler.domain.generateMonthCalendarDays
import com.simpleshift.scheduler.domain.model.MonthlyStats
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
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
    val stats: MonthlyStats? = null
)

class CalendarViewModel(
    application: Application,
    private val localeProvider: () -> Locale = { Locale.getDefault() },
    private val monthProvider: () -> YearMonth = { YearMonth.now() }
) : AndroidViewModel(application) {

    // Secondary constructor for Android ViewModelProvider
    constructor(application: Application) : this(
        application = application,
        localeProvider = { Locale.getDefault() },
        monthProvider = { YearMonth.now() }
    )

    private val _uiState = MutableStateFlow(CalendarUiState())
    val uiState: StateFlow<CalendarUiState> = _uiState.asStateFlow()

    private var currentMonth: YearMonth = monthProvider()
    private var selectedTeamId: Int = 1

    var customCycle: List<ShiftType>? = null

    private fun teamPhaseStep(): Int {
        val totalDays = customCycle?.size ?: ShiftCycleConfig.CYCLE_LENGTH
        return totalDays / Team.TOTAL_TEAMS
    }

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

    fun computeStats() {
        val teamPhaseOffset = (selectedTeamId - 1) * teamPhaseStep()
        val days = generateMonthCalendarDays(
            currentMonth,
            teamPhaseOffset = teamPhaseOffset,
            customCycle = customCycle
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
        val teamPhaseOffset = (selectedTeamId - 1) * teamPhaseStep()

        val days = generateMonthCalendarDays(
            currentMonth,
            teamPhaseOffset = teamPhaseOffset,
            customCycle = customCycle
        )
            .map { day ->
                CalendarDayUiState(
                    dateNumber = day.date.dayOfMonth,
                    shiftLabel = mapShiftLabel(day.shiftType),
                    shiftType = day.shiftType,
                    isCurrentMonth = day.isCurrentMonth,
                    isToday = day.date == LocalDate.now()
                )
            }

        _uiState.value = _uiState.value.copy(
            monthLabel = currentMonth.format(monthFormatter),
            weekLabels = weekLabels,
            days = days,
            stats = null
        )
    }

    private fun mapShiftLabel(shiftType: ShiftType): String {
        val resId = when (shiftType) {
            ShiftType.MORNING -> R.string.shift_label_morning
            ShiftType.AFTERNOON -> R.string.shift_label_afternoon
            ShiftType.REST -> R.string.shift_label_rest
            ShiftType.NIGHT -> R.string.shift_label_night
            ShiftType.STUDY -> R.string.shift_label_study
        }
        return getApplication<Application>().getString(resId)
    }
}
