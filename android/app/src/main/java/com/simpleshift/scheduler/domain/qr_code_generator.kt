package com.simpleshift.scheduler.domain

import android.graphics.Bitmap
import android.graphics.Color
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter

/** QR code destination URL. Replace with app store link after publication. */
const val SHARE_QR_URL = "https://www.bilibili.com"

/**
 * Generate a QR code Bitmap for the given content string.
 * ZXing QRCodeWriter → BitMatrix → Android Bitmap.
 *
 * @param content The string to encode in the QR code
 * @param sizePx Output square size in pixels (default 600 = 200dp @ 3x)
 * @return ARGB_8888 Bitmap, black foreground on white background
 */
fun generateQrCodeBitmap(content: String, sizePx: Int = 600): Bitmap {
    val bitMatrix = QRCodeWriter().encode(content, BarcodeFormat.QR_CODE, sizePx, sizePx)
    val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
    for (x in 0 until sizePx) {
        for (y in 0 until sizePx) {
            bitmap.setPixel(x, y, if (bitMatrix[x, y]) Color.BLACK else Color.WHITE)
        }
    }
    return bitmap
}
