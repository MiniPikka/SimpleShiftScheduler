package com.simpleshift.scheduler.util

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.view.View
import android.view.ViewGroup
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.platform.ComposeView
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileOutputStream
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

/**
 * Render a @Composable off-screen into a fixed-size Bitmap.
 * MUST be called on the main thread.
 *
 * Temporarily attaches a ComposeView to the Activity's decor view (invisible)
 * so it gets a WindowRecomposer, waits for the first composition frame via
 * [LaunchedEffect], then forces measure/layout/draw onto a Bitmap and detaches.
 */
suspend fun Activity.renderComposableToBitmap(
    widthPx: Int,
    heightPx: Int,
    content: @Composable () -> Unit
): Bitmap {
    val composeView = ComposeView(this)
    val decorView = window.decorView as ViewGroup

    try {
        // Attach to window (invisible) so ComposeView gets WindowRecomposer
        composeView.alpha = 0f
        decorView.addView(composeView, ViewGroup.LayoutParams(widthPx, heightPx))

        // Wait for the first composition frame to complete
        suspendCoroutine<Unit> { cont ->
            composeView.setContent {
                content()
                LaunchedEffect(Unit) {
                    cont.resume(Unit)
                }
            }
        }

        // Force exact pixel dimensions
        composeView.measure(
            View.MeasureSpec.makeMeasureSpec(widthPx, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(heightPx, View.MeasureSpec.EXACTLY)
        )
        composeView.layout(0, 0, widthPx, heightPx)

        // Draw to bitmap
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bitmap)
        composeView.draw(canvas)
        return bitmap
    } finally {
        decorView.removeView(composeView)
    }
}

/**
 * Save a Bitmap as PNG to the share_images cache directory,
 * returning a FileProvider-backed content:// URI safe for cross-app sharing.
 */
fun Context.saveBitmapToShareCache(bitmap: Bitmap, filename: String): Uri {
    val shareDir = File(cacheDir, "share_images").apply { mkdirs() }
    val file = File(shareDir, "$filename.png")
    FileOutputStream(file).use { fos ->
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos)
    }
    return FileProvider.getUriForFile(this, "${packageName}.fileprovider", file)
}

/**
 * Delete share cache files older than 24 hours.
 * Safe to call on every app start — handles missing directories gracefully.
 */
fun Context.cleanupOldShareImages() {
    val shareDir = File(cacheDir, "share_images")
    if (!shareDir.exists()) return
    val cutoff = System.currentTimeMillis() - 24 * 60 * 60 * 1000L
    shareDir.listFiles()?.forEach { file ->
        if (file.lastModified() < cutoff) file.delete()
    }
}
