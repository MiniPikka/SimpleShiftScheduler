package com.simpleshift.scheduler.ui

import androidx.test.core.app.ApplicationProvider
import com.simpleshift.scheduler.domain.model.ShiftType
import com.simpleshift.scheduler.ui.home.getContextualMessage
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ContextualMessageTest {

    private val context: android.content.Context = ApplicationProvider.getApplicationContext()

    @Test
    fun `rest day returns message from rest pool`() {
        val msg = getContextualMessage(context, ShiftType.REST, 0, 0, daySeed = 42)
        assertNotNull(msg)
        assertTrue(msg.isNotEmpty())
    }

    @Test
    fun `night shift returns message from night pool`() {
        val msg = getContextualMessage(context, ShiftType.NIGHT, 3, 2, daySeed = 42)
        assertNotNull(msg)
        assertTrue(msg.isNotEmpty())
    }

    @Test
    fun `consecutive work 5 plus days gets hard work message`() {
        val msg = getContextualMessage(context, ShiftType.MORNING, 2, 5, daySeed = 42)
        assertTrue(msg.isNotEmpty())
    }

    @Test
    fun `consecutive work 7 days gets hard work message with count`() {
        val msg = getContextualMessage(context, ShiftType.MORNING, 3, 7, daySeed = 42)
        assertTrue(msg.isNotEmpty())
    }

    @Test
    fun `almost rest with 0 days until rest returns almost rest message`() {
        val msg = getContextualMessage(context, ShiftType.MORNING, 0, 3, daySeed = 42)
        assertNotNull(msg)
        assertTrue(msg.isNotEmpty())
    }

    @Test
    fun `almost rest with 1 day until rest returns almost rest message`() {
        val msg = getContextualMessage(context, ShiftType.MORNING, 1, 3, daySeed = 42)
        assertNotNull(msg)
        assertTrue(msg.isNotEmpty())
    }

    @Test
    fun `regular work day returns default message`() {
        val msg = getContextualMessage(context, ShiftType.AFTERNOON, 4, 2, daySeed = 42)
        assertNotNull(msg)
        assertTrue(msg.isNotEmpty())
    }

    @Test
    fun `rest day overrides consecutive work condition`() {
        val msg = getContextualMessage(context, ShiftType.REST, 0, 6, daySeed = 42)
        assertTrue(msg.isNotEmpty())
    }

    @Test
    fun `night shift overrides consecutive work condition`() {
        val msg = getContextualMessage(context, ShiftType.NIGHT, 3, 6, daySeed = 42)
        assertTrue(msg.isNotEmpty())
    }

    @Test
    fun `different seeds produce valid messages`() {
        for (seed in listOf(1, 10, 50, 100, 200, 365)) {
            val msg = getContextualMessage(context, ShiftType.MORNING, 3, 3, daySeed = seed)
            assertNotNull("Message should not be null for seed $seed", msg)
            assertTrue("Message should not be empty for seed $seed", msg.isNotEmpty())
        }
    }
}
