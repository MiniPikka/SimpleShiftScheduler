package com.simpleshift.scheduler.domain.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDate

class AlarmTimeTest {

    @Test
    fun `constructs with valid hour and minute`() {
        val time = AlarmTime(7, 30)
        assertEquals(7, time.hour)
        assertEquals(30, time.minute)
    }

    @Test
    fun `constructs at boundaries`() {
        val midnight = AlarmTime(0, 0)
        assertEquals(0, midnight.hour)
        assertEquals(0, midnight.minute)

        val lastMinute = AlarmTime(23, 59)
        assertEquals(23, lastMinute.hour)
        assertEquals(59, lastMinute.minute)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `rejects hour below 0`() {
        AlarmTime(-1, 0)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `rejects hour above 23`() {
        AlarmTime(24, 0)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `rejects minute below 0`() {
        AlarmTime(7, -1)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `rejects minute above 59`() {
        AlarmTime(7, 60)
    }

    @Test
    fun `toEpochMillis returns positive value for future date`() {
        val future = LocalDate.now().plusDays(1)
        val time = AlarmTime(12, 0)
        val millis = time.toEpochMillis(future)
        assert(millis > System.currentTimeMillis())
    }

    @Test
    fun `toEpochMillis returns value before now for past time today`() {
        val today = LocalDate.now()
        val time = AlarmTime(0, 0) // midnight
        val millis = time.toEpochMillis(today)
        // Midnight today is in the past (unless it's exactly midnight)
        assert(millis <= System.currentTimeMillis())
    }
}
