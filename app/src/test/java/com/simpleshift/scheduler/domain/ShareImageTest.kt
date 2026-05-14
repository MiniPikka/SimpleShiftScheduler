package com.simpleshift.scheduler.domain

import android.graphics.Bitmap
import android.graphics.Color
import com.simpleshift.scheduler.ui.colleague_mode.ShareCardData
import com.simpleshift.scheduler.util.cleanupOldShareImages
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import java.io.File
import java.net.URL

@RunWith(RobolectricTestRunner::class)
class ShareImageTest {

    // ---- QR Code generation tests ----

    @Test
    fun `generateQrCode returns non-null bitmap`() {
        val bitmap = generateQrCodeBitmap("https://example.com")
        assertNotNull(bitmap)
    }

    @Test
    fun `generateQrCode correct size`() {
        val size = 300
        val bitmap = generateQrCodeBitmap("test", sizePx = size)
        assertEquals(size, bitmap.width)
        assertEquals(size, bitmap.height)
    }

    @Test
    fun `generateQrCode has black and white pixels`() {
        val bitmap = generateQrCodeBitmap("https://example.com", sizePx = 200)
        var hasBlack = false
        var hasWhite = false
        for (x in 0 until bitmap.width) {
            for (y in 0 until bitmap.height) {
                val pixel = bitmap.getPixel(x, y)
                if (pixel == Color.BLACK) hasBlack = true
                if (pixel == Color.WHITE) hasWhite = true
            }
        }
        assertTrue("QR code should have black pixels", hasBlack)
        assertTrue("QR code should have white pixels", hasWhite)
    }

    @Test
    fun `different content produces different bitmaps`() {
        val bitmap1 = generateQrCodeBitmap("https://example.com/a", sizePx = 100)
        val bitmap2 = generateQrCodeBitmap("https://example.com/b", sizePx = 100)

        var identical = true
        outer@ for (x in 0 until 100) {
            for (y in 0 until 100) {
                if (bitmap1.getPixel(x, y) != bitmap2.getPixel(x, y)) {
                    identical = false
                    break@outer
                }
            }
        }
        assertFalse("Different URLs should produce different QR codes", identical)
    }

    // ---- URL constant test ----

    @Test
    fun `SHARE_QR_URL is valid URL`() {
        val url = URL(SHARE_QR_URL)
        assertNotNull(url.protocol)
        assertNotNull(url.host)
    }

    // ---- ShareCardData model test ----

    @Test
    fun `ShareCardData all fields populated correctly`() {
        val qrBitmap = generateQrCodeBitmap(SHARE_QR_URL)
        val data = ShareCardData(
            teamAName = "一值",
            teamBName = "三值",
            nextCommonRestDate = "5月28日",
            nextCommonRestWeekday = "星期三",
            daysUntilNext = 14,
            countIn30Days = 3,
            countIn60Days = 7,
            commonRestDateItems = listOf("5月28日 星期三", "6月3日 星期二"),
            dateRange = "2026/05/14 — 12/31",
            qrCodeBitmap = qrBitmap
        )

        assertEquals("一值", data.teamAName)
        assertEquals("三值", data.teamBName)
        assertEquals("5月28日", data.nextCommonRestDate)
        assertEquals("星期三", data.nextCommonRestWeekday)
        assertEquals(14, data.daysUntilNext)
        assertEquals(3, data.countIn30Days)
        assertEquals(7, data.countIn60Days)
        assertEquals(2, data.commonRestDateItems.size)
        assertEquals("2026/05/14 — 12/31", data.dateRange)
        assertEquals(qrBitmap, data.qrCodeBitmap)
    }

    // ---- Cache cleanup tests ----

    @Test
    fun `cleanupOldShareImages removes expired files`() {
        val context = RuntimeEnvironment.getApplication()
        val shareDir = File(context.cacheDir, "share_images")
        shareDir.mkdirs()

        val oldFile = File(shareDir, "old_file.png")
        oldFile.writeBytes(ByteArray(100))
        oldFile.setLastModified(System.currentTimeMillis() - 25 * 60 * 60 * 1000L) // 25 hours ago

        val newFile = File(shareDir, "new_file.png")
        newFile.writeBytes(ByteArray(100))

        context.cleanupOldShareImages()

        assertFalse("Expired file should be deleted", oldFile.exists())
        assertTrue("Recent file should remain", newFile.exists())

        // Clean up
        newFile.delete()
        shareDir.delete()
    }

    @Test
    fun `cleanupOldShareImages handles non-existent dir`() {
        val context = RuntimeEnvironment.getApplication()
        val shareDir = File(context.cacheDir, "share_images")
        if (shareDir.exists()) shareDir.deleteRecursively()

        // Should not throw
        context.cleanupOldShareImages()
    }
}
