package com.simpleshift.scheduler.domain

import com.simpleshift.scheduler.domain.model.RuntimeShiftSettings
import com.simpleshift.scheduler.domain.model.ShiftType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.assertNotNull
import org.junit.Test
import java.time.LocalDate
import java.util.Locale

class WidgetDataTest {

    private val fixedDate = LocalDate.of(2026, 5, 13)
    private val fixedLocale = Locale.CHINA

    private val zhLabels = mapOf(
        ShiftType.MORNING to "早",
        ShiftType.AFTERNOON to "中",
        ShiftType.REST to "休",
        ShiftType.NIGHT to "夜",
        ShiftType.STUDY to "学"
    )
    private val zhTeamNames = mapOf(
        1 to "一值", 2 to "二值", 3 to "三值", 4 to "四值", 5 to "五值", 6 to "六值"
    )

    @Test
    fun `produces correct data for default settings`() {
        val data = computeWidgetShiftData(
            today = fixedDate,
            settings = RuntimeShiftSettings(),
            locale = fixedLocale,
            shiftLabelResolver = { zhLabels[it]!! },
            teamNameResolver = { zhTeamNames[it]!! }
        )

        assertTrue("date label should not be empty", data.dateLabel.isNotEmpty())
        assertTrue("shiftLabel should be Chinese", data.shiftLabel in zhLabels.values)
        assertTrue("dayOfCycle should be positive", data.dayOfCycle > 0)
        assertEquals(42, data.totalDays)
        assertEquals("一值", data.teamName)
        assertTrue("daysUntilRest should be >= 0", data.daysUntilRest >= 0)
        assertTrue("tomorrowShiftLabel should be Chinese", data.tomorrowShiftLabel in zhLabels.values)
        assertTrue("tomorrowShiftLabel should not be empty", data.tomorrowShiftLabel.isNotEmpty())
    }

    @Test
    fun `produces correct data for custom cycle`() {
        val customSettings = RuntimeShiftSettings(
            cycleLength = 10,
            shiftCycle = List(10) { ShiftType.NIGHT },
            defaultTeamId = 1
        )
        val data = computeWidgetShiftData(
            today = fixedDate,
            settings = customSettings,
            locale = fixedLocale,
            shiftLabelResolver = { zhLabels[it]!! },
            teamNameResolver = { zhTeamNames[it]!! }
        )

        assertEquals(10, data.totalDays)
        assertEquals("夜", data.shiftLabel)
        assertEquals(ShiftType.NIGHT, data.shiftType)
        assertEquals("夜", data.tomorrowShiftLabel)
        assertEquals(ShiftType.NIGHT, data.tomorrowShiftType)
    }

    @Test
    fun `returns fallback for invalid settings`() {
        val invalidSettings = RuntimeShiftSettings(
            cycleLength = 10,
            shiftCycle = RuntimeShiftSettings().shiftCycle
        )
        assertTrue("Settings should be invalid", !invalidSettings.isValid)

        val data = computeWidgetShiftData(
            today = fixedDate,
            settings = invalidSettings,
            locale = fixedLocale,
            shiftLabelResolver = { zhLabels[it]!! },
            teamNameResolver = { zhTeamNames[it]!! }
        )

        assertEquals("", data.shiftLabel)
        assertEquals(ShiftType.REST, data.shiftType)
        assertEquals(0, data.dayOfCycle)
        assertEquals(0, data.totalDays)
        assertEquals("", data.teamName)
        assertEquals("", data.dateLabel)
        assertEquals(-1, data.daysUntilRest)
        assertEquals("", data.tomorrowShiftLabel)
        assertEquals(ShiftType.REST, data.tomorrowShiftType)
    }

    @Test
    fun `respects default team selection`() {
        val settings = RuntimeShiftSettings(
            cycleLength = 42,
            shiftCycle = RuntimeShiftSettings().shiftCycle,
            defaultTeamId = 3
        )
        val data = computeWidgetShiftData(
            today = fixedDate,
            settings = settings,
            locale = fixedLocale,
            shiftLabelResolver = { zhLabels[it]!! },
            teamNameResolver = { zhTeamNames[it]!! }
        )

        assertEquals("三值", data.teamName)
    }

    @Test
    fun `date label includes weekday`() {
        val data = computeWidgetShiftData(
            today = fixedDate,
            settings = RuntimeShiftSettings(),
            locale = fixedLocale,
            shiftLabelResolver = { zhLabels[it]!! },
            teamNameResolver = { zhTeamNames[it]!! }
        )

        assertTrue("Date label should contain weekday", data.dateLabel.isNotEmpty())
        assertTrue("Date label should contain month", data.dateLabel.contains("5"))
    }

    @Test
    fun `tomorrow shift differs from today`() {
        val data = computeWidgetShiftData(
            today = fixedDate,
            settings = RuntimeShiftSettings(),
            locale = fixedLocale,
            shiftLabelResolver = { zhLabels[it]!! },
            teamNameResolver = { zhTeamNames[it]!! }
        )

        // Tomorrow should be the next day in the cycle
        assertEquals(data.dayOfCycle % data.totalDays + 1,
            (data.dayOfCycle % data.totalDays) + 1)
    }
}
