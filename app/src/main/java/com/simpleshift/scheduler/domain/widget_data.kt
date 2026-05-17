package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import com.simpleshift.scheduler.util.ShiftLabelMapper
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

data class WidgetShiftData(
    val dateLabel: String,
    val shiftLabel: String,
    val shiftType: ShiftType,
    val dayOfCycle: Int,
    val totalDays: Int,
    val teamName: String,
    val daysUntilRest: Int,
    val tomorrowShiftLabel: String,
    val tomorrowShiftType: ShiftType
)

fun computeWidgetShiftData(
    today: LocalDate = LocalDate.now(),
    settings: RuntimeShiftSettings = RuntimeShiftSettings(),
    locale: Locale = Locale.getDefault()
): WidgetShiftData {
    if (!settings.isValid) {
        return WidgetShiftData(
            dateLabel = "",
            shiftLabel = "未配置",
            shiftType = ShiftType.REST,
            dayOfCycle = 0,
            totalDays = 0,
            teamName = "请先设置排班规则",
            daysUntilRest = -1,
            tomorrowShiftLabel = "",
            tomorrowShiftType = ShiftType.REST
        )
    }

    val teamPhaseOffset = (settings.defaultTeamId - 1) *
        (settings.shiftCycle.size / Team.TOTAL_TEAMS)
    val shiftInfo = getShiftInfo(today, teamPhaseOffset, settings.shiftCycle, settings.referenceDate)
    val tomorrowInfo = getShiftInfo(today.plusDays(1), teamPhaseOffset, settings.shiftCycle, settings.referenceDate)
    val team = Team.ALL_TEAMS.find { it.id == settings.defaultTeamId }
        ?: Team.ALL_TEAMS.first()

    val dateFormatter = DateTimeFormatter.ofPattern("M月d日", locale)
    val dayOfWeek = dayOfWeekChinese(today.dayOfWeek)

    return WidgetShiftData(
        dateLabel = "${today.format(dateFormatter)} $dayOfWeek",
        shiftLabel = ShiftLabelMapper.toLabel(shiftInfo.shiftType),
        shiftType = shiftInfo.shiftType,
        dayOfCycle = shiftInfo.dayOfCycle,
        totalDays = settings.shiftCycle.size,
        teamName = team.name,
        daysUntilRest = daysUntilNextRest(today, teamPhaseOffset, settings.shiftCycle, settings.referenceDate),
        tomorrowShiftLabel = ShiftLabelMapper.toLabel(tomorrowInfo.shiftType),
        tomorrowShiftType = tomorrowInfo.shiftType
    )
}

private fun dayOfWeekChinese(dayOfWeek: DayOfWeek): String = when (dayOfWeek) {
    DayOfWeek.MONDAY -> "周一"
    DayOfWeek.TUESDAY -> "周二"
    DayOfWeek.WEDNESDAY -> "周三"
    DayOfWeek.THURSDAY -> "周四"
    DayOfWeek.FRIDAY -> "周五"
    DayOfWeek.SATURDAY -> "周六"
    DayOfWeek.SUNDAY -> "周日"
}
