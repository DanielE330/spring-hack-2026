package com.example.entry_point

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import kotlin.math.min
import kotlin.math.sqrt

/**
 * Рендерит весь визуал домашнего виджета в один Bitmap.
 *
 * Визуал полностью повторяет Flutter-компонент _CircularTimerWithQr:
 *   • тёмный фон 0xFF1A1A2E с закруглёнными углами 16dp (reference)
 *   • кольцо прогресса (фоновая дорожка + цветная дуга) — от -90° по часовой
 *   • белый круг (D=270dp) в центре
 *   • QR-код, вписанный в белый круг
 *   • цветной текст таймера ⏱ MM:SS под кольцом
 *   • подпись «QR обновится автоматически»
 *
 * Все размеры указаны в dp (reference 400dp = [REF_DP]),
 * при рендере масштабируются через [scale].
 */
object WidgetBitmapRenderer {

    // ── Опорные размеры (dp) ─────────────────────────────────────────────────

    private const val REF_DP = 400f          // ширина и высота опорного холста
    private const val CIRCLE_DP = 300f       // диаметр кольца таймера
    private const val WHITE_CIRCLE_DP = 270f // диаметр белого круга
    private const val STROKE_DP = 8f         // толщина дуги
    private const val CIRCLE_TOP_DP = 36f    // отступ кольца сверху
    private const val TIMER_FS_DP = 18f      // размер текста таймера
    private const val SUBTITLE_FS_DP = 12f   // размер подписи
    private const val BG_CORNER_DP = 20f     // скругление фона

    // ── Цвета ────────────────────────────────────────────────────────────────

    private const val COLOR_BG     = 0xFF1A1A2E.toInt()
    private const val COLOR_GREEN  = 0xFF4CAF50.toInt()
    private const val COLOR_ORANGE = 0xFFFF9800.toInt()
    private const val COLOR_RED    = 0xFFE74C3C.toInt()
    private const val COLOR_WHITE  = 0xFFFFFFFF.toInt()

    /**
     * @param qrToken     содержимое QR-кода
     * @param secondsLeft оставшееся время жизни QR (сек.)
     * @param totalSeconds полное время жизни (по умолчанию 300)
     * @param outputPx    сторона итогового квадратного Bitmap в пикселях
     */
    fun render(
        qrToken: String,
        secondsLeft: Int,
        totalSeconds: Int = 300,
        outputPx: Int = 800
    ): Bitmap {
        val bmp = Bitmap.createBitmap(outputPx, outputPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = outputPx / REF_DP // масштаб

        drawBackground(canvas, outputPx.toFloat(), s)

        val fraction = if (totalSeconds > 0)
            (secondsLeft.toFloat() / totalSeconds).coerceIn(0f, 1f) else 0f

        val arcColor = timerColor(fraction)

        val circleCenterX = outputPx / 2f
        val circleCenterY = CIRCLE_TOP_DP * s + CIRCLE_DP * s / 2f

        drawCircularTimer(canvas, circleCenterX, circleCenterY, fraction, arcColor, s)
        drawWhiteCircleQr(canvas, circleCenterX, circleCenterY, qrToken, s)

        val circleBottom = circleCenterY + CIRCLE_DP * s / 2f
        drawTimerText(canvas, circleCenterX, circleBottom, secondsLeft, arcColor, s)
        drawSubtitle(canvas, circleCenterX, circleBottom, s)

        return bmp
    }

    /**
     * Рендерит состояние ошибки или загрузки (без QR).
     */
    fun renderStatus(
        message: String,
        outputPx: Int = 800
    ): Bitmap {
        val bmp = Bitmap.createBitmap(outputPx, outputPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = outputPx / REF_DP

        drawBackground(canvas, outputPx.toFloat(), s)

        // Круг-заглушка (пустая дорожка)
        val circleCenterX = outputPx / 2f
        val circleCenterY = CIRCLE_TOP_DP * s + CIRCLE_DP * s / 2f
        drawCircularTimer(canvas, circleCenterX, circleCenterY, 0f, 0xFF888888.toInt(), s)

        // Текст ошибки / загрузки по центру
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xCCFFFFFF.toInt()
            textSize = 16f * s
            textAlign = Paint.Align.CENTER
            typeface = Typeface.DEFAULT
        }
        canvas.drawText(message, circleCenterX, circleCenterY + textPaint.textSize / 2f, textPaint)

        return bmp
    }

    // ── Приватные helpers ─────────────────────────────────────────────────────

    private fun drawBackground(canvas: Canvas, size: Float, s: Float) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = COLOR_BG }
        val r = BG_CORNER_DP * s
        canvas.drawRoundRect(0f, 0f, size, size, r, r, paint)
    }

    private fun drawCircularTimer(
        canvas: Canvas,
        cx: Float,
        cy: Float,
        fraction: Float,
        arcColor: Int,
        s: Float
    ) {
        val stroke = STROKE_DP * s
        val radius = CIRCLE_DP * s / 2f - stroke / 2f

        // Дорожка (trackColor: тот же цвет с alpha=0x23, как во Flutter)
        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = (arcColor and 0x00FFFFFF) or 0x23000000
            style = Paint.Style.STROKE
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawCircle(cx, cy, radius, trackPaint)

        // Дуга прогресса — от -90° (12 часов) по часовой
        if (fraction > 0f) {
            val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = arcColor
                style = Paint.Style.STROKE
                strokeWidth = stroke
                strokeCap = Paint.Cap.ROUND
            }
            val oval = RectF(cx - radius, cy - radius, cx + radius, cy + radius)
            canvas.drawArc(oval, -90f, 360f * fraction, false, progressPaint)
        }
    }

    private fun drawWhiteCircleQr(
        canvas: Canvas,
        cx: Float,
        cy: Float,
        qrToken: String,
        s: Float
    ) {
        val whiteRadius = WHITE_CIRCLE_DP * s / 2f

        // Белый круг
        val whitePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = COLOR_WHITE
            style = Paint.Style.FILL
        }
        canvas.drawCircle(cx, cy, whiteRadius, whitePaint)

        // QR внутри — размер = (270 / √2) − 24dp, как во Flutter
        val qrSizePx = ((WHITE_CIRCLE_DP / sqrt(2.0)) * s - 24 * s).toInt().coerceAtLeast(64)
        val qrBitmap = QrBitmapGenerator.generate(qrToken, qrSizePx)
        val left = cx - qrSizePx / 2f
        val top = cy - qrSizePx / 2f
        canvas.drawBitmap(qrBitmap, left, top, null)
    }

    private fun drawTimerText(
        canvas: Canvas,
        cx: Float,
        circleBottom: Float,
        secondsLeft: Int,
        color: Int,
        s: Float
    ) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            textSize = TIMER_FS_DP * s
            textAlign = Paint.Align.CENTER
            typeface = Typeface.DEFAULT_BOLD
        }
        val m = secondsLeft / 60
        val sec = secondsLeft % 60
        val text = "⏱ ${String.format("%02d:%02d", m, sec)}"
        canvas.drawText(text, cx, circleBottom + 16f * s + paint.textSize, paint)
    }

    private fun drawSubtitle(
        canvas: Canvas,
        cx: Float,
        circleBottom: Float,
        s: Float
    ) {
        val timerLineH = TIMER_FS_DP * s
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0x99FFFFFF.toInt()
            textSize = SUBTITLE_FS_DP * s
            textAlign = Paint.Align.CENTER
        }
        val y = circleBottom + 16f * s + timerLineH + 8f * s + paint.textSize
        canvas.drawText("QR обновится автоматически", cx, y, paint)
    }

    private fun timerColor(fraction: Float): Int = when {
        fraction > 0.5f -> COLOR_GREEN
        fraction > 0.2f -> COLOR_ORANGE
        else            -> COLOR_RED
    }
}
