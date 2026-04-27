package com.simpleshift.scheduler.viewmodel

import androidx.test.core.app.ApplicationProvider
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

@RunWith(RobolectricTestRunner::class)
class HomeViewModelTest {

    @Test
    fun `init emits expected ui state fields`() {
        val testDate = ShiftCycleConfig.REFERENCE_DATE
        val locale = Locale.SIMPLIFIED_CHINESE
        val expectedDateLabel = testDate.format(
            DateTimeFormatter.ofLocalizedDate(FormatStyle.FULL).withLocale(locale)
        )

        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { testDate },
            localeProvider = { locale }
        )

        val uiState = viewModel.uiState.value
        assertEquals(expectedDateLabel, uiState.todayDate)
        assertEquals(ShiftType.MORNING, uiState.shiftType)
        assertEquals("早", uiState.shiftLabel)
        assertEquals(1, uiState.dayOfCycle)
        assertEquals(ShiftCycleConfig.CYCLE_LENGTH, uiState.totalDays)
    }

    @Test
    fun `refreshToday updates state when date changes`() {
        val locale = Locale.SIMPLIFIED_CHINESE
        var currentDate = ShiftCycleConfig.REFERENCE_DATE
        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { currentDate },
            localeProvider = { locale }
        )
        val initialState = viewModel.uiState.value

        currentDate = ShiftCycleConfig.REFERENCE_DATE.plusDays(4)
        viewModel.refreshToday()
        val refreshedState = viewModel.uiState.value

        assertEquals(ShiftType.REST, refreshedState.shiftType)
        assertEquals("休", refreshedState.shiftLabel)
        assertEquals(5, refreshedState.dayOfCycle)
        assertFalse(initialState.todayDate == refreshedState.todayDate)
    }

    @Test
    fun `shift label mapping stays fixed for all shift types`() {
        val locale = Locale.SIMPLIFIED_CHINESE
        val expectedLabels = mapOf(
            ShiftType.MORNING to "早",
            ShiftType.AFTERNOON to "中",
            ShiftType.REST to "休",
            ShiftType.NIGHT to "夜",
            ShiftType.STUDY to "学"
        )

        expectedLabels.forEach { (shiftType, expectedLabel) ->
            val dateForShift = findDateForShiftType(shiftType)
            val viewModel = HomeViewModel(
                application = ApplicationProvider.getApplicationContext(),
                currentDateProvider = { dateForShift },
                localeProvider = { locale }
            )

            assertEquals(expectedLabel, viewModel.uiState.value.shiftLabel)
            assertEquals(shiftType, viewModel.uiState.value.shiftType)
        }
    }

    @Test
    fun `init emits available teams`() {
        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { ShiftCycleConfig.REFERENCE_DATE },
            localeProvider = { Locale.SIMPLIFIED_CHINESE }
        )

        val uiState = viewModel.uiState.value
        assertEquals(Team.TOTAL_TEAMS, uiState.availableTeams.size)
        assertEquals(1, uiState.selectedTeamId)
        assertEquals("班组1", uiState.availableTeams.first().name)
        assertEquals("班组6", uiState.availableTeams.last().name)
    }

    @Test
    fun `selectTeam updates selected team and refreshes shift`() {
        val testDate = ShiftCycleConfig.REFERENCE_DATE
        val locale = Locale.SIMPLIFIED_CHINESE
        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { testDate },
            localeProvider = { locale }
        )

        // Default team 1: MORNING on reference date
        assertEquals(ShiftType.MORNING, viewModel.uiState.value.shiftType)
        assertEquals(1, viewModel.uiState.value.selectedTeamId)

        // Switch to team 2 (offset 7): should be REST on reference date
        viewModel.selectTeam(2)
        assertEquals(2, viewModel.uiState.value.selectedTeamId)
        assertEquals(ShiftType.REST, viewModel.uiState.value.shiftType)
    }

    @Test
    fun `selectTeam updates shift label correctly`() {
        val testDate = ShiftCycleConfig.REFERENCE_DATE
        val locale = Locale.SIMPLIFIED_CHINESE
        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { testDate },
            localeProvider = { locale }
        )

        viewModel.selectTeam(3)
        assertEquals(ShiftType.NIGHT, viewModel.uiState.value.shiftType)
        assertEquals("夜", viewModel.uiState.value.shiftLabel)
    }

    private fun findDateForShiftType(shiftType: ShiftType): LocalDate {
        val index = ShiftCycleConfig.SHIFT_CYCLE.indexOf(shiftType)
        require(index >= 0) { "ShiftType not found in configured cycle: $shiftType" }
        return ShiftCycleConfig.REFERENCE_DATE.plusDays(index.toLong())
    }
}
