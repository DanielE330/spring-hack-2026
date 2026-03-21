package com.example.entry_point

import android.graphics.Bitmap
import android.graphics.Color

/**
 * Генерация QR-кода как Bitmap без внешних зависимостей.
 * Простая реализация на основе алгоритма QR-кодирования не подходит —
 * используем встроенный ZXing через bundled зависимость.
 * 
 * Fallback: если ZXing недоступен, генерируем placeholder.
 */
object QrBitmapGenerator {

    fun generate(data: String, sizePx: Int = 512): Bitmap {
        return try {
            generateWithZxing(data, sizePx)
        } catch (e: Exception) {
            generatePlaceholder(sizePx)
        }
    }

    private fun generateWithZxing(data: String, sizePx: Int): Bitmap {
        val writer = com.google.zxing.qrcode.QRCodeWriter()
        val hints = mapOf(
            com.google.zxing.EncodeHintType.MARGIN to 1,
            com.google.zxing.EncodeHintType.ERROR_CORRECTION to com.google.zxing.qrcode.decoder.ErrorCorrectionLevel.M
        )
        val bitMatrix = writer.encode(data, com.google.zxing.BarcodeFormat.QR_CODE, sizePx, sizePx, hints)
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        for (x in 0 until sizePx) {
            for (y in 0 until sizePx) {
                bitmap.setPixel(x, y, if (bitMatrix.get(x, y)) Color.BLACK else Color.WHITE)
            }
        }
        return bitmap
    }

    private fun generatePlaceholder(sizePx: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(Color.LTGRAY)
        return bitmap
    }
}
