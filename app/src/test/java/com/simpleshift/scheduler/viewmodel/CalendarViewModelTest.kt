package com.simpleshift.scheduler.viewmodel

import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.time.LocalDate
import java.time.YearMonth
import java.util.Locale

@RunWith(RobolectricTestRunner::class)
class CalendarViewModelTest {

    private val fixedMonth = YearMonth.of(2026, 5)
    private val fixedToday = LocalDate.of(2026, 5, 13) // A Wednesday
    private val fixedLocale = Locale.CHINA

    private fun createViewModel(
        month: YearMonth = fixedMonth,
        today: LocalDate = fixedToday
    ): CalendarViewModel = CalendarViewModel(
        application = ApplicationProvider.getApplicationContext(),
        localeProvider = { fixedLocale },
        monthProvider = { month },
        todayProvider = { today }
    )

    @Test
    fun `initial state produces 42 days and non-empty month label`() {
        val vm = createViewModel()
        val state = vm.uiState.value

        assertEquals("Days should be 42 grid cells", 42, state.days.size)
        assertTrue("Month label should not be empty", state.monthLabel.isNotEmpty())
        assertTrue("Should start on current month", state.isCurrentMonth)
    }

    @Test
    fun `weekLabels contain correct order`() {
        val vm = createViewModel()
        val state = vm.uiState.value

        assertEquals(7, state.weekLabels.size)
        assertEquals("日", state.weekLabels[0])
        assertEquals("一", state.weekLabels[1])
        assertEquals("二", state.weekLabels[2])
        assertEquals("三", state.weekLabels[3])
        assertEquals("四", state.weekLabels[4])
        assertEquals("五", state.weekLabels[5])
        assertEquals("六", state.weekLabels[6])
    }

    @Test
    fun `goToPreviousMonth changes monthLabel`() {
        val vm = createViewModel(month = YearMonth.of(2026, 5))
        val labelBefore = vm.uiState.value.monthLabel

        vm.goToPreviousMonth()
        val labelAfter = vm.uiState.value.monthLabel

        assertTrue("Month label should change", labelBefore != labelAfter)
        assertFalse("Should not be on current month after navigating away",
            vm.uiState.value.isCurrentMonth)
    }

    @Test
    fun `goToNextMonth changes monthLabel`() {
        val vm = createViewModel(month = YearMonth.of(2026, 5))
        val labelBefore = vm.uiState.value.monthLabel

        vm.goToNextMonth()
        val labelAfter = vm.uiState.value.monthLabel

        assertTrue("Month label should change", labelBefore != labelAfter)
        assertFalse("Should not be on current month", vm.uiState.value.isCurrentMonth)
    }

    @Test
    fun `goToToday resets to current month`() {
        val vm = createViewModel(month = YearMonth.of(2026, 5))

        // Navigate away
        vm.goToNextMonth()
        vm.goToNextMonth()
        assertFalse("Should be away from current month", vm.uiState.value.isCurrentMonth)

        // Go back to today
        vm.goToToday()
        assertTrue("Should return to current month", vm.uiState.value.isCurrentMonth)
    }

    @Test
    fun `isToday marks correct cell`() {
        val vm = createViewModel(
            month = YearMonth.of(2026, 5),
            today = LocalDate.of(2026, 5, 13)
        )

        val state = vm.uiState.value
        val todayCells = state.days.filter { it.isToday }

        assertEquals("Exactly one cell should be marked as today", 1, todayCells.size)
        assertEquals("Today's date number should be 13", 13, todayCells[0].dateNumber)
    }

    @Test
    fun `computeStats produces non-null stats`() {
        val vm = createViewModel()
        assertNull("Stats should start null", vm.uiState.value.stats)

        vm.computeStats()
        val stats = vm.uiState.value.stats
        assertNotNull("Stats should not be null after compute", stats)
        // All counts should be non-negative
        assertTrue(stats!!.morningCount >= 0)
        assertTrue(stats.afternoonCount >= 0)
        assertTrue(stats.restCount >= 0)
        assertTrue(stats.nightCount >= 0)
        assertTrue(stats.studyCount >= 0)
    }

    @Test
    fun `dismissStats clears stats to null`() {
        val vm = createViewModel()
        vm.computeStats()
        assertNotNull("Stats should exist before dismiss", vm.uiState.value.stats)

        vm.dismissStats()
        assertNull("Stats should be null after dismiss", vm.uiState.value.stats)
    }

    @Test
    fun `setTeam changes shift labels in days`() {
        val vm = createViewModel()
        val team1Labels = vm.uiState.value.days.map { it.shiftLabel }

        vm.setTeam(3)
        val team3Labels = vm.uiState.value.days.map { it.shiftLabel }

        // With a proper cycle, different team offsets should produce different shift labels
        // at least for some days (unless all days in the 42-grid have the same shift)
        val hasDifference = team1Labels.zip(team3Labels).any { (a, b) -> a != b }
        assertTrue("Shift labels should change when switching teams", hasDifference)
    }
}
