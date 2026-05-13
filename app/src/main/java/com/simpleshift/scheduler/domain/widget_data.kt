package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import com.simpleshift.scheduler.util.ShiftLabelMapper
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

data class WidgetShiftData(
    val dateLabel: String,
    val shiftLabel: String,
    val shiftType: ShiftType,
    val dayOfCycle: Int,
    val totalDays: Int,
    val teamName: String
)

fun computeWidgetShiftData(
    today: LocalDate = LocalDate.now(),
    settings: RuntimeShiftSettings = RuntimeShiftSettings(),
    locale: Locale = Locale.getDefault()
): WidgetShiftData {
    if (!settings.isValid) {
        return WidgetShiftData(
            dateLabel = "",
            shiftLabel = "?",
            shiftType = ShiftType.REST,
            dayOfCycle = 0,
            totalDays = 0,
            teamName = ""
        )
    }

    val teamPhaseOffset = (settings.defaultTeamId - 1) *
        (settings.shiftCycle.size / Team.TOTAL_TEAMS)
    val shiftInfo = getShiftInfo(today, teamPhaseOffset, settings.shiftCycle)
    val team = Team.ALL_TEAMS.find { it.id == settings.defaultTeamId }
        ?: Team.ALL_TEAMS.first()
    val dateFormatter = DateTimeFormatter
        .ofLocalizedDate(FormatStyle.FULL)
        .withLocale(locale)

    return WidgetShiftData(
        dateLabel = today.format(dateFormatter),
        shiftLabel = ShiftLabelMapper.toLabel(shiftInfo.shiftType),
        shiftType = shiftInfo.shiftType,
        dayOfCycle = shiftInfo.dayOfCycle,
        totalDays = settings.shiftCycle.size,
        teamName = team.name
    )
}
