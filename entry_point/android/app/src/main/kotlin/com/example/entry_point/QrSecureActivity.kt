package com.example.entry_point

import android.os.Bundle
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import java.util.Timer
import java.util.TimerTask

/**
 * Activity, открываемая при тапе на виджет рабочего стола.
 * FLAG_SECURE запрещает скриншоты и запись экрана.
 *
 * Показывает QR-код с обратным отсчётом и кнопкой обновления.
 */
class QrSecureActivity : AppCompatActivity() {

    private var countdownTimer: Timer? = null
    private var secondsLeft = 300

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ─── FLAG_SECURE — запрет скриншотов ─────────────────
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

        // ─── Максимальная яркость ────────────────────────────
        val layoutParams = window.attributes
        layoutParams.screenBrightness = 1.0f
        window.attributes = layoutParams

        // ─── UI программно (без отдельного layout) ────────────
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = android.view.Gravity.CENTER
            setPadding(48, 48, 48, 48)
            setBackgroundColor(0xFF1A1A2E.toInt())
        }

        val titleText = TextView(this).apply {
            text = "Ваш QR-пропуск"
            textSize = 22f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
        }

        val qrLp = LinearLayout.LayoutParams(600, 600).apply { topMargin = 32 }
        val qrImageView = ImageView(this).apply {
            scaleType = ImageView.ScaleType.FIT_CENTER
            setBackgroundColor(0xFFFFFFFF.toInt())
            setPadding(24, 24, 24, 24)
        }

        val timerLp = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = 24 }
        val timerText = TextView(this).apply {
            text = "Загрузка..."
            textSize = 18f
            setTextColor(0xFF4CAF50.toInt())
            gravity = android.view.Gravity.CENTER
        }

        val progressLp = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 24
        ).apply { topMargin = 16 }
        val progressBar = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 300
            progress = 300
            progressDrawable = android.graphics.drawable.ClipDrawable(
                android.graphics.drawable.ColorDrawable(0xFF4CAF50.toInt()),
                android.view.Gravity.START,
                android.graphics.drawable.ClipDrawable.HORIZONTAL
            )
            setBackgroundColor(0x33FFFFFF)
        }

        val btnLp = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = 24 }
        val refreshButton = android.widget.Button(this).apply {
            text = "Обновить QR"
            textSize = 16f
        }

        val statusLp = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = 16 }
        val statusText = TextView(this).apply {
            text = "Защищено от скриншотов"
            textSize = 12f
            setTextColor(0x99FFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
        }

        root.addView(titleText)
        root.addView(qrImageView, qrLp)
        root.addView(progressBar, progressLp)
        root.addView(timerText, timerLp)
        root.addView(refreshButton, btnLp)
        root.addView(statusText, statusLp)

        setContentView(root)

        // ─── Загрузка QR ────────────────────────────────────
        fun loadQr() {
            timerText.text = "Загрузка..."
            countdownTimer?.cancel()

            Thread {
                val qrData = fetchQrToken()
                runOnUiThread {
                    if (qrData != null) {
                        val bitmap = QrBitmapGenerator.generate(qrData.token, 512)
                        qrImageView.setImageBitmap(bitmap)
                        secondsLeft = qrData.secondsLeft

                        progressBar.max = 300
                        progressBar.progress = secondsLeft
                        startCountdown(timerText, progressBar) {
                            loadQr() // авто-обновление по истечению
                        }
                    } else {
                        timerText.text = "Ошибка загрузки"
                        timerText.setTextColor(0xFFE74C3C.toInt())
                    }
                }
            }.start()
        }

        refreshButton.setOnClickListener { loadQr() }
        loadQr()
    }

    private fun startCountdown(
        timerText: TextView,
        progressBar: ProgressBar,
        onExpired: () -> Unit
    ) {
        countdownTimer?.cancel()
        countdownTimer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    secondsLeft--
                    runOnUiThread {
                        if (secondsLeft <= 0) {
                            cancel()
                            onExpired()
                        } else {
                            val m = secondsLeft / 60
                            val s = secondsLeft % 60
                            timerText.text = String.format("%02d:%02d", m, s)
                            progressBar.progress = secondsLeft

                            val color = when {
                                secondsLeft > 150 -> 0xFF4CAF50.toInt() // green
                                secondsLeft > 60  -> 0xFFFF9800.toInt() // orange
                                else               -> 0xFFE74C3C.toInt() // red
                            }
                            timerText.setTextColor(color)
                        }
                    }
                }
            }, 1000, 1000)
        }
    }

    private fun fetchQrToken(): QrPassWidgetProvider.QrData? {
        return try {
            val masterKey = androidx.security.crypto.MasterKey.Builder(this)
                .setKeyScheme(androidx.security.crypto.MasterKey.KeyScheme.AES256_GCM)
                .build()
            val prefs = androidx.security.crypto.EncryptedSharedPreferences.create(
                this,
                "FlutterSecureStorage",
                masterKey,
                androidx.security.crypto.EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                androidx.security.crypto.EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
            val deviceCode = prefs.getString(
                "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_device_code", null
            ) ?: return null

            val url = java.net.URL("http://194.113.106.32/qr/generate/")
            val conn = url.openConnection() as java.net.HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Authorization", "Token $deviceCode")
            conn.connectTimeout = 10_000
            conn.readTimeout = 10_000
            conn.doOutput = true
            conn.outputStream.use { it.write("""{"force_new": true}""".toByteArray()) }

            if (conn.responseCode == 200) {
                val json = conn.inputStream.bufferedReader().readText()
                val obj = org.json.JSONObject(json)
                QrPassWidgetProvider.QrData(
                    token = obj.getString("token"),
                    secondsLeft = obj.optInt("seconds_left", 300)
                )
            } else null
        } catch (e: Exception) {
            null
        }
    }

    override fun onDestroy() {
        countdownTimer?.cancel()
        super.onDestroy()
    }
}
