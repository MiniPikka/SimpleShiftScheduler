package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
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
    locale: Locale = Locale.getDefault(),
    shiftLabelResolver: (ShiftType) -> String = { it.name },
    teamNameResolver: (Int) -> String = { "Team $it" }
): WidgetShiftData {
    if (!settings.isValid) {
        return WidgetShiftData(
            dateLabel = "",
            shiftLabel = "",
            shiftType = ShiftType.REST,
            dayOfCycle = 0,
            totalDays = 0,
            teamName = "",
            daysUntilRest = -1,
            tomorrowShiftLabel = "",
            tomorrowShiftType = ShiftType.REST
        )
    }

    val teamPhaseOffset = (settings.defaultTeamId - 1) *
        (settings.shiftCycle.size / Team.TOTAL_TEAMS)
    val shiftInfo = getShiftInfo(today, teamPhaseOffset, settings.shiftCycle, settings.referenceDate)
    val tomorrowInfo = getShiftInfo(today.plusDays(1), teamPhaseOffset, settings.shiftCycle, settings.referenceDate)

    val dateFormatter = DateTimeFormatter.ofLocalizedDate(java.time.format.FormatStyle.MEDIUM).withLocale(locale)
    val dayOfWeek = today.dayOfWeek.getDisplayName(TextStyle.FULL, locale)

    return WidgetShiftData(
        dateLabel = "$dayOfWeek ${today.format(dateFormatter)}",
        shiftLabel = shiftLabelResolver(shiftInfo.shiftType),
        shiftType = shiftInfo.shiftType,
        dayOfCycle = shiftInfo.dayOfCycle,
        totalDays = settings.shiftCycle.size,
        teamName = teamNameResolver(settings.defaultTeamId),
        daysUntilRest = daysUntilNextRest(today, teamPhaseOffset, settings.shiftCycle, settings.referenceDate),
        tomorrowShiftLabel = shiftLabelResolver(tomorrowInfo.shiftType),
        tomorrowShiftType = tomorrowInfo.shiftType
    )
}
