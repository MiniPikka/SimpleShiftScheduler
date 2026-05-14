package com.simpleshift.scheduler.viewmodel

import android.app.Activity
import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.simpleshift.scheduler.domain.findCommonRestDays
import com.simpleshift.scheduler.domain.generateQrCodeBitmap
import com.simpleshift.scheduler.domain.SHARE_QR_URL
import com.simpleshift.scheduler.domain.model.CommonRestResult
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import com.simpleshift.scheduler.ui.colleague_mode.ShareCardData
import com.simpleshift.scheduler.ui.colleague_mode.ShareCardLayout
import com.simpleshift.scheduler.util.renderComposableToBitmap
import com.simpleshift.scheduler.util.saveBitmapToShareCache
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
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
        val errorMessage: String? = null,
        val isSharing: Boolean = false,
        val shareUri: Uri? = null,
        val shareError: String? = null
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

    fun startShare(activity: Activity) {
        if (_uiState.value.isSharing) return
        val state = _uiState.value
        val result = state.result ?: run {
            _uiState.value = state.copy(shareError = "无分享数据")
            return
        }

        _uiState.value = state.copy(isSharing = true, shareError = null)

        viewModelScope.launch {
            try {
                val app = getApplication<Application>()

                val shareCardData = withContext(Dispatchers.Default) {
                    buildShareCardData(result, state)
                }

                // renderComposableToBitmap is suspend, must run on Main (accesses decorView)
                val bitmap = activity.renderComposableToBitmap(1080, 1920) {
                    ShareCardLayout(data = shareCardData)
                }

                val uri = withContext(Dispatchers.IO) {
                    app.saveBitmapToShareCache(bitmap, "colleague_${System.currentTimeMillis()}")
                }

                _uiState.value = _uiState.value.copy(shareUri = uri, isSharing = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isSharing = false,
                    shareError = "生成分享图失败: ${e.localizedMessage ?: "未知错误"}"
                )
            }
        }
    }

    fun onShareComplete() {
        _uiState.value = _uiState.value.copy(shareUri = null)
    }

    fun clearShareError() {
        _uiState.value = _uiState.value.copy(shareError = null)
    }

    private fun buildShareCardData(result: CommonRestResult, state: ColleagueModeUiState): ShareCardData {
        val qrBitmap = generateQrCodeBitmap(SHARE_QR_URL)

        val dateFormatter = DateTimeFormatter.ofPattern("M月d日")
        val weekNames = mapOf(
            java.time.DayOfWeek.MONDAY to "星期一",
            java.time.DayOfWeek.TUESDAY to "星期二",
            java.time.DayOfWeek.WEDNESDAY to "星期三",
            java.time.DayOfWeek.THURSDAY to "星期四",
            java.time.DayOfWeek.FRIDAY to "星期五",
            java.time.DayOfWeek.SATURDAY to "星期六",
            java.time.DayOfWeek.SUNDAY to "星期日"
        )

        val date = result.nextCommonRestDate
        val dateItems = result.commonRestDates.take(12).map { d ->
            val weekName = weekNames[d.dayOfWeek] ?: ""
            "${d.format(dateFormatter)} $weekName"
        }

        return ShareCardData(
            teamAName = result.teamAName,
            teamBName = result.teamBName,
            nextCommonRestDate = date?.format(dateFormatter) ?: "无",
            nextCommonRestWeekday = date?.let { weekNames[it.dayOfWeek] } ?: "",
            daysUntilNext = result.daysUntilNext ?: -1,
            countIn30Days = result.countIn30Days,
            countIn60Days = result.countIn60Days,
            commonRestDateItems = dateItems,
            dateRange = state.analyzedDateRange,
            qrCodeBitmap = qrBitmap
        )
    }

    @Suppress("unused")
    constructor(application: Application) : this(
        application = application,
        todayProvider = { LocalDate.now() }
    )
}
