package com.simpleshift.scheduler.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.simpleshift.scheduler.domain.findCommonRestDays
import com.simpleshift.scheduler.domain.model.CommonRestResult
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

class ColleagueModeViewModel(
    application: Application,
    private val todayProvider: () -> LocalDate = { LocalDate.now() }
) : AndroidViewModel(application) {

    data class ColleagueModeUiState(
        val teamAId: Int = 1,
        val teamBId: Int = 3,
        val result: CommonRestResult? = null,
        val analyzedDateRange: String = "",
        val isLoading: Boolean = true,
        val errorMessage: String? = null
    )

    private val _uiState = MutableStateFlow(ColleagueModeUiState())
    val uiState: StateFlow<ColleagueModeUiState> = _uiState.asStateFlow()

    private var customCycle: List<ShiftType>? = null
    private var referenceDate: LocalDate? = null

    fun setTeamA(teamId: Int) {
        _uiState.value = _uiState.value.copy(teamAId = teamId, isLoading = true)
        val cycle = customCycle ?: return
        val ref = referenceDate ?: return
        refresh(cycle, ref)
    }

    fun setTeamB(teamId: Int) {
        _uiState.value = _uiState.value.copy(teamBId = teamId, isLoading = true)
        val cycle = customCycle ?: return
        val ref = referenceDate ?: return
        refresh(cycle, ref)
    }

    fun swapTeams() {
        val state = _uiState.value
        _uiState.value = state.copy(
            teamAId = state.teamBId,
            teamBId = state.teamAId,
            isLoading = true
        )
        val cycle = customCycle ?: return
        val ref = referenceDate ?: return
        refresh(cycle, ref)
    }

    fun refresh(
        customCycle: List<ShiftType>?,
        referenceDate: LocalDate
    ) {
        this.customCycle = customCycle
        this.referenceDate = referenceDate

        val today = todayProvider()
        val endOfYear = LocalDate.of(today.year, 12, 31)
        val daysToAnalyze = ChronoUnit.DAYS.between(today, endOfYear).toInt() + 1

        val state = _uiState.value
        val result = try {
            findCommonRestDays(
                teamAId = state.teamAId,
                teamBId = state.teamBId,
                today = today,
                daysToAnalyze = daysToAnalyze,
                customCycle = customCycle,
                referenceDate = referenceDate
            )
        } catch (e: Exception) {
            _uiState.value = state.copy(
                isLoading = false,
                errorMessage = "分析失败: ${e.localizedMessage ?: "未知错误"}"
            )
            return
        }

        val range = "${today.format(DateTimeFormatter.ofPattern("yyyy/MM/dd"))} — ${endOfYear.format(DateTimeFormatter.ofPattern("MM/dd"))}"

        _uiState.value = state.copy(
            result = result,
            analyzedDateRange = range,
            isLoading = false,
            errorMessage = null
        )
    }

    @Suppress("unused")
    constructor(application: Application) : this(
        application = application,
        todayProvider = { LocalDate.now() }
    )
}
