package com.simpleshift.scheduler.viewmodel

import androidx.test.core.app.ApplicationProvider
import com.simpleshift.scheduler.domain.model.AlarmSettings
import com.simpleshift.scheduler.domain.model.AlarmTime
import com.simpleshift.scheduler.domain.model.ShiftCycleConfig
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.domain.model.Team
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
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
        assertTrue("shiftLabel should not be empty", uiState.shiftLabel.isNotEmpty())
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
        assertTrue("shiftLabel should not be empty", refreshedState.shiftLabel.isNotEmpty())
        assertEquals(5, refreshedState.dayOfCycle)
        assertFalse(initialState.todayDate == refreshedState.todayDate)
    }

    @Test
    fun `shift label mapping stays fixed for all shift types`() {
        val locale = Locale.SIMPLIFIED_CHINESE

        ShiftType.entries.forEach { shiftType ->
            val dateForShift = findDateForShiftType(shiftType)
            val viewModel = HomeViewModel(
                application = ApplicationProvider.getApplicationContext(),
                currentDateProvider = { dateForShift },
                localeProvider = { locale }
            )

            assertEquals(shiftType, viewModel.uiState.value.shiftType)
            assertTrue("shiftLabel should not be empty for $shiftType",
                viewModel.uiState.value.shiftLabel.isNotEmpty())
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
        assertEquals(1, uiState.availableTeams.first().id)
        assertEquals(6, uiState.availableTeams.last().id)
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

        assertEquals(ShiftType.MORNING, viewModel.uiState.value.shiftType)
        assertEquals(1, viewModel.uiState.value.selectedTeamId)

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
        assertTrue("shiftLabel should not be empty", viewModel.uiState.value.shiftLabel.isNotEmpty())
    }

    @Test
    fun `teamName is derived from selectedTeamId`() {
        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { ShiftCycleConfig.REFERENCE_DATE },
            localeProvider = { Locale.SIMPLIFIED_CHINESE }
        )
        assertTrue("teamName should not be empty", viewModel.uiState.value.teamName.isNotEmpty())

        viewModel.selectTeam(3)
        assertTrue("teamName should not be empty after team change",
            viewModel.uiState.value.teamName.isNotEmpty())
    }

    @Test
    fun `metric fields are populated after refresh`() {
        val testDate = ShiftCycleConfig.REFERENCE_DATE
        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { testDate },
            localeProvider = { Locale.SIMPLIFIED_CHINESE }
        )
        val state = viewModel.uiState.value
        assertTrue("totalDaysInMonth should be > 0", state.totalDaysInMonth > 0)
        assertTrue("monthlyWorkDays should be >= 0", state.monthlyWorkDays >= 0)
        assertTrue("monthlyWorkDays should be <= totalDaysInMonth",
            state.monthlyWorkDays <= state.totalDaysInMonth)
        assertTrue("consecutiveWorkDays should be >= 0", state.consecutiveWorkDays >= 0)
        assertTrue("daysUntilRest should be >= 0", state.daysUntilRest >= 0)
    }

    @Test
    fun `shiftTimeRange is null when no alarm configured`() {
        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { ShiftCycleConfig.REFERENCE_DATE },
            localeProvider = { Locale.SIMPLIFIED_CHINESE }
        )
        assertNull(viewModel.uiState.value.shiftTimeRange)
    }

    @Test
    fun `shiftTimeRange is populated after updateAlarmSettings`() {
        val testDate = ShiftCycleConfig.REFERENCE_DATE
        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { testDate },
            localeProvider = { Locale.SIMPLIFIED_CHINESE }
        )
        val alarmTime = AlarmTime(6, 30)
        val alarms = mapOf(ShiftType.MORNING to alarmTime)
        viewModel.updateAlarmSettings(AlarmSettings(alarms))

        assertEquals("06:30", viewModel.uiState.value.shiftTimeRange)
    }

    @Test
    fun `workIntensity is computed in valid range`() {
        val testDate = ShiftCycleConfig.REFERENCE_DATE
        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { testDate },
            localeProvider = { Locale.SIMPLIFIED_CHINESE }
        )
        val state = viewModel.uiState.value
        assertTrue("workIntensity >= 0", state.workIntensity >= 0)
        assertTrue("workIntensity <= 100", state.workIntensity <= 100)
    }

    @Test
    fun `monthlyShiftTypeCount is positive for existing shift type`() {
        val testDate = ShiftCycleConfig.REFERENCE_DATE
        val viewModel = HomeViewModel(
            application = ApplicationProvider.getApplicationContext(),
            currentDateProvider = { testDate },
            localeProvider = { Locale.SIMPLIFIED_CHINESE }
        )
        val state = viewModel.uiState.value
        assertEquals(ShiftType.MORNING, state.shiftType)
        assertTrue("monthlyShiftTypeCount > 0", state.monthlyShiftTypeCount > 0)
        assertTrue("monthlyShiftTypeCount <= totalDaysInMonth",
            state.monthlyShiftTypeCount <= state.totalDaysInMonth)
    }

    private fun findDateForShiftType(shiftType: ShiftType): LocalDate {
        val index = ShiftCycleConfig.SHIFT_CYCLE.indexOf(shiftType)
        require(index >= 0) { "ShiftType not found in configured cycle: $shiftType" }
        return ShiftCycleConfig.REFERENCE_DATE.plusDays(index.toLong())
    }
}
