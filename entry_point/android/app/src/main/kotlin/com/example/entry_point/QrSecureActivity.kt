package com.example.entry_point

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import java.util.Timer
import java.util.TimerTask
import kotlin.math.min
import kotlin.math.sqrt

/**
 * Activity, открываемая при тапе на виджет рабочего стола.
 *
 * • FLAG_SECURE  — запрещает скриншоты и запись экрана
 * • Максимальная яркость экрана при показе QR
 * • Круговой таймер обратного отсчёта (идентичен Flutter-реализации):
 *     – дуга зелёного / оранжевого / красного цвета вокруг QR-кода
 *     – fraction > 0.5 → зелёный, > 0.2 → оранжевый, иначе красный
 */
class QrSecureActivity : AppCompatActivity() {

    private var countdownTimer: Timer? = null
    private var secondsLeft = 300
    private val totalSeconds = 300

    // UI-элементы, обновляемые из таймера
    private lateinit var circularTimerView: CircularTimerView
    private lateinit var qrImageView: ImageView
    private lateinit var timerText: TextView
    private lateinit var refreshButton: Button

    // dp → px
    private fun dp(value: Float): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Запрет скриншотов / записи экрана
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

        // Максимальная яркость — важно для сканера QR на турникете
        window.attributes = window.attributes.also { it.screenBrightness = 1.0f }

        buildUi()

        refreshButton.setOnClickListener { loadQr() }
        loadQr()
    }

    // ─── Построение UI ────────────────────────────────────────────────────────

    private fun buildUi() {
        val scroll = ScrollView(this).apply {
            setBackgroundColor(0xFF1A1A2E.toInt())
        }
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24f), dp(48f), dp(24f), dp(32f))
        }
        scroll.addView(root, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)

        // Заголовок
        root.addView(TextView(this).apply {
            text = "Ваш QR-пропуск"
            textSize = 22f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dp(24f))
        }, lp(w = LinearLayout.LayoutParams.MATCH_PARENT))

        // ── Круговой таймер + QR внутри (300dp × 300dp) ─────────────────────
        // Соответствует SizedBox(300, 300) + CircularTimerPainter во Flutter
        val circleSizePx = dp(300f)

        val frame = FrameLayout(this)

        // Кастомный View — рисует фоновую дорожку и цветную дугу
        circularTimerView = CircularTimerView(this).apply {
            strokeWidthPx = dp(8f).toFloat()
        }
        frame.addView(circularTimerView, FrameLayout.LayoutParams(circleSizePx, circleSizePx))

        // Белый круг с QR внутри (270dp), вписанный в центр
        // qrSize = (270dp / √2) − 24dp — точно как во Flutter
        val qrContainerSizePx = dp(270f)
        val qrSizePx = ((qrContainerSizePx / sqrt(2.0)) - dp(24f)).toInt()

        val qrContainer = FrameLayout(this).apply {
            background = android.graphics.drawable.ShapeDrawable(
                android.graphics.drawable.shapes.OvalShape()
            ).also { it.paint.color = 0xFFFFFFFF.toInt() }
        }

        qrImageView = ImageView(this).apply {
            scaleType = ImageView.ScaleType.FIT_CENTER
        }
        qrContainer.addView(
            qrImageView,
            FrameLayout.LayoutParams(qrSizePx, qrSizePx, Gravity.CENTER)
        )
        frame.addView(
            qrContainer,
            FrameLayout.LayoutParams(qrContainerSizePx, qrContainerSizePx, Gravity.CENTER)
        )

        root.addView(frame, lp(w = circleSizePx, h = circleSizePx))

        // ── Текст таймера: иконка + ММ:СС ────────────────────────────────────
        val timerRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, dp(14f), 0, 0)
        }
        timerRow.addView(TextView(this).apply {
            text = "⏱"
            textSize = 18f
            setPadding(0, 0, dp(6f), 0)
        })
        timerText = TextView(this).apply {
            text = "Загрузка..."
            textSize = 18f
            setTextColor(COLOR_GREEN)
            gravity = Gravity.CENTER
        }
        timerRow.addView(timerText)
        root.addView(timerRow, lp())

        // Подпись
        root.addView(TextView(this).apply {
            text = "QR обновится автоматически"
            textSize = 12f
            setTextColor(0x99FFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, dp(6f), 0, 0)
        }, lp(w = LinearLayout.LayoutParams.MATCH_PARENT))

        // Кнопка «Обновить QR»
        refreshButton = Button(this).apply {
            text = "Обновить QR"
            textSize = 16f
        }
        root.addView(refreshButton, lp(w = LinearLayout.LayoutParams.MATCH_PARENT, topMargin = dp(20f)))

        // Статус
        root.addView(TextView(this).apply {
            text = "🔒 Защищено от скриншотов"
            textSize = 11f
            setTextColor(0x66FFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, dp(12f), 0, 0)
        }, lp(w = LinearLayout.LayoutParams.MATCH_PARENT))

        setContentView(scroll)
    }

    // ─── Загрузка QR ──────────────────────────────────────────────────────────

    private fun loadQr() {
        timerText.text = "Загрузка..."
        timerText.setTextColor(COLOR_GREEN)
        circularTimerView.setProgress(1f, COLOR_GREEN)
        countdownTimer?.cancel()

        Thread {
            val result = fetchQrToken()
            runOnUiThread {
                when {
                    result.data != null -> {
                        val bitmap = QrBitmapGenerator.generate(result.data.token, 512)
                        qrImageView.setImageBitmap(bitmap)
                        secondsLeft = result.data.secondsLeft.coerceIn(1, totalSeconds)
                        updateTimerUi()
                        startCountdown()
                    }
                    else -> {
                        timerText.text = result.error ?: "Ошибка загрузки"
                        timerText.setTextColor(COLOR_RED)
                        circularTimerView.setProgress(0f, COLOR_RED)
                        Log.e(TAG, "loadQr failed: ${result.error}")
                    }
                }
            }
        }.start()
    }

    // ─── Таймер обратного отсчёта ─────────────────────────────────────────────

    private fun startCountdown() {
        countdownTimer?.cancel()
        countdownTimer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    secondsLeft--
                    runOnUiThread {
                        if (secondsLeft <= 0) {
                            cancel()
                            loadQr() // автообновление по истечению
                        } else {
                            updateTimerUi()
                        }
                    }
                }
            }, 1000L, 1000L)
        }
    }

    /**
     * Обновляет дугу, цвет и текст таймера.
     * Цветовые пороги идентичны Flutter (_CircularTimerPainter):
     *   fraction > 0.5  → зелёный
     *   fraction > 0.2  → оранжевый
     *   иначе           → красный
     */
    private fun updateTimerUi() {
        val fraction = (secondsLeft.toFloat() / totalSeconds).coerceIn(0f, 1f)
        val color = timerColor(fraction)

        val m = secondsLeft / 60
        val s = secondsLeft % 60
        timerText.text = String.format("%02d:%02d", m, s)
        timerText.setTextColor(color)
        circularTimerView.setProgress(fraction, color)
    }

    // ─── Получение QR-токена ──────────────────────────────────────────────────

    private data class FetchResult(
        val data: QrPassWidgetProvider.QrData? = null,
        val error: String? = null
    )

    private fun fetchQrToken(): FetchResult {
        // 1. Читаем device_code из EncryptedSharedPreferences Flutter Secure Storage
        val deviceCode: String
        try {
            // applicationContext обязателен — иначе на некоторых устройствах исключение
            val masterKey = androidx.security.crypto.MasterKey.Builder(applicationContext)
                .setKeyScheme(androidx.security.crypto.MasterKey.KeyScheme.AES256_GCM)
                .build()
            val prefs = androidx.security.crypto.EncryptedSharedPreferences.create(
                applicationContext,
                "FlutterSecureStorage",
                masterKey,
                androidx.security.crypto.EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                androidx.security.crypto.EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
            val code = prefs.getString(
                "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_device_code", null
            )
            if (code.isNullOrEmpty()) {
                Log.w(TAG, "device_code не найден — пользователь не авторизован")
                return FetchResult(error = "Войдите в приложение")
            }
            deviceCode = code
        } catch (e: Exception) {
            Log.e(TAG, "Ошибка EncryptedSharedPreferences", e)
            return FetchResult(error = "Ошибка хранилища: ${e.javaClass.simpleName}")
        }

        // 2. POST /qr/generate/
        return try {
            val url = java.net.URL("http://194.113.106.32/qr/generate/")
            val conn = url.openConnection() as java.net.HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Authorization", "Token $deviceCode")
            conn.connectTimeout = 10_000
            conn.readTimeout = 10_000
            conn.doOutput = true
            conn.outputStream.use { it.write("""{"force_new": true}""".toByteArray()) }

            val httpCode = conn.responseCode
            Log.d(TAG, "qr/generate/ → HTTP $httpCode")
            if (httpCode == 200) {
                val json = conn.inputStream.bufferedReader().readText()
                val obj = org.json.JSONObject(json)
                FetchResult(
                    data = QrPassWidgetProvider.QrData(
                        token = obj.getString("token"),
                        secondsLeft = obj.optInt("seconds_left", 300)
                    )
                )
            } else {
                val body = runCatching { conn.errorStream?.bufferedReader()?.readText() }.getOrNull()
                Log.e(TAG, "Сервер вернул $httpCode: $body")
                FetchResult(error = "Сервер: HTTP $httpCode")
            }
        } catch (e: java.net.UnknownHostException) {
            Log.e(TAG, "Нет сети", e); FetchResult(error = "Нет соединения с сервером")
        } catch (e: java.net.SocketTimeoutException) {
            Log.e(TAG, "Таймаут", e); FetchResult(error = "Сервер не отвечает (таймаут)")
        } catch (e: Exception) {
            Log.e(TAG, "Ошибка запроса", e); FetchResult(error = "Ошибка сети: ${e.javaClass.simpleName}")
        }
    }

    override fun onDestroy() {
        countdownTimer?.cancel()
        super.onDestroy()
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    /** LayoutParams с центрированием по горизонтали */
    private fun lp(
        w: Int = LinearLayout.LayoutParams.WRAP_CONTENT,
        h: Int = LinearLayout.LayoutParams.WRAP_CONTENT,
        topMargin: Int = 0
    ) = LinearLayout.LayoutParams(w, h).also {
        it.topMargin = topMargin
        it.gravity = Gravity.CENTER_HORIZONTAL
    }

    companion object {
        private const val TAG = "QrSecureActivity"

        val COLOR_GREEN  = 0xFF4CAF50.toInt()
        val COLOR_ORANGE = 0xFFFF9800.toInt()
        val COLOR_RED    = 0xFFE74C3C.toInt()

        /** Цвет по доле времени — идентично Flutter (_CircularTimerWithQr._timerColor) */
        fun timerColor(fraction: Float): Int = when {
            fraction > 0.5f -> COLOR_GREEN
            fraction > 0.2f -> COLOR_ORANGE
            else             -> COLOR_RED
        }
    }
}

// ─── CircularTimerView ────────────────────────────────────────────────────────

/**
 * Нативный аналог Flutter-класса _CircularTimerPainter.
 *
 * Рисует:
 * 1. Фоновую дорожку (полную окружность) — цвет дуги с alpha ~14% (35/255)
 * 2. Цветную дугу прогресса от -90° (12 часов) по часовой стрелке
 *
 * Для обновления вызывайте [setProgress].
 */
class CircularTimerView(context: Context) : View(context) {

    /** Толщина дуги в пикселях */
    var strokeWidthPx: Float = 16f

    private var fraction: Float = 1f
    private var arcColor: Int = QrSecureActivity.COLOR_GREEN

    private val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
    }
    private val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
    }

    private val oval = RectF()

    /**
     * @param fraction  доля оставшегося времени [0.0 … 1.0]
     * @param color     цвет дуги (COLOR_GREEN / COLOR_ORANGE / COLOR_RED)
     */
    fun setProgress(fraction: Float, color: Int) {
        this.fraction = fraction.coerceIn(0f, 1f)
        this.arcColor = color
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        val cx = width / 2f
        val cy = height / 2f
        val radius = min(width, height) / 2f - strokeWidthPx / 2f

        oval.set(cx - radius, cy - radius, cx + radius, cy + radius)

        // Фоновая дорожка: тот же цвет с alpha=35 (как в Flutter trackColor)
        trackPaint.color = (arcColor and 0x00FFFFFF) or 0x23000000
        trackPaint.strokeWidth = strokeWidthPx
        canvas.drawCircle(cx, cy, radius, trackPaint)

        // Прогресс-дуга
        progressPaint.color = arcColor
        progressPaint.strokeWidth = strokeWidthPx
        canvas.drawArc(oval, -90f, 360f * fraction, false, progressPaint)
    }
}
