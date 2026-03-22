package com.example.entry_point

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.util.concurrent.Executors

/**
 * Android Home Screen Widget — показывает QR-пропуск.
 *
 * Обновляется каждые 5 минут (updatePeriodMillis=300000).
 * При тапе открывает QrSecureActivity с FLAG_SECURE.
 */
class QrPassWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "FlutterSecureStorage"
        private const val KEY_DEVICE_CODE = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_device_code"
        private const val BASE_URL = "http://194.113.106.32"
        private const val QR_GENERATE_URL = "$BASE_URL/qr/generate/"

        /** Принудительное обновление всех виджетов извне */
        fun forceUpdate(context: Context) {
            val intent = Intent(context, QrPassWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, QrPassWidgetProvider::class.java))
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            context.sendBroadcast(intent)
        }
    }

    private val executor = Executors.newSingleThreadExecutor()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            // Сначала показываем «Обновление...»
            val loadingViews = RemoteViews(context.packageName, R.layout.widget_qr_pass).apply {
                setTextViewText(R.id.widget_timer_text, "Обновление...")
            }
            appWidgetManager.updateAppWidget(widgetId, loadingViews)

            // Загружаем QR в фоне
            executor.execute {
                updateWidget(context, appWidgetManager, widgetId)
            }
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_qr_pass)

        try {
            // Получаем device_code из EncryptedSharedPreferences
            val deviceCode = getDeviceCode(context)
            if (deviceCode.isNullOrEmpty()) {
                views.setTextViewText(R.id.widget_timer_text, "Войдите в приложение")
                views.setTextViewText(R.id.widget_status_text, "")
                appWidgetManager.updateAppWidget(widgetId, views)
                return
            }

            // Запрос на генерацию QR
            val qrData = fetchQrToken(deviceCode)
            if (qrData != null) {
                val bitmap = QrBitmapGenerator.generate(qrData.token, 512)
                views.setImageViewBitmap(R.id.widget_qr_image, bitmap)

                val minutes = qrData.secondsLeft / 60
                val seconds = qrData.secondsLeft % 60
                views.setTextViewText(
                    R.id.widget_timer_text,
                    String.format("Действует %02d:%02d", minutes, seconds)
                )
                views.setTextViewText(R.id.widget_status_text, "Нажмите для просмотра")
            } else {
                views.setTextViewText(R.id.widget_timer_text, "Ошибка загрузки")
                views.setTextViewText(R.id.widget_status_text, "Нажмите для повтора")
            }
        } catch (e: Exception) {
            views.setTextViewText(R.id.widget_timer_text, "Нет соединения")
            views.setTextViewText(R.id.widget_status_text, "Нажмите для повтора")
        }

        // По тапу открываем защищённую Activity
        val tapIntent = Intent(context, QrSecureActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    /**
     * Получение device_code из EncryptedSharedPreferences Flutter Secure Storage.
     */
    private fun getDeviceCode(context: Context): String? {
        return try {
            val masterKey = androidx.security.crypto.MasterKey.Builder(context)
                .setKeyScheme(androidx.security.crypto.MasterKey.KeyScheme.AES256_GCM)
                .build()
            val prefs = androidx.security.crypto.EncryptedSharedPreferences.create(
                context,
                PREFS_NAME,
                masterKey,
                androidx.security.crypto.EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                androidx.security.crypto.EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
            prefs.getString(KEY_DEVICE_CODE, null)
        } catch (e: Exception) {
            null
        }
    }

    /**
     * HTTP-запрос на /qr/generate/ с device_code.
     */
    private fun fetchQrToken(deviceCode: String): QrData? {
        return try {
            val url = java.net.URL(QR_GENERATE_URL)
            val conn = url.openConnection() as java.net.HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Authorization", "Token $deviceCode")
            conn.connectTimeout = 10_000
            conn.readTimeout = 10_000
            conn.doOutput = true

            val body = """{"force_new": true}"""
            conn.outputStream.use { it.write(body.toByteArray()) }

            if (conn.responseCode == 200) {
                val response = conn.inputStream.bufferedReader().readText()
                parseQrResponse(response)
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun parseQrResponse(json: String): QrData? {
        return try {
            // Простой JSON-парсинг без внешней библиотеки
            val org = org.json.JSONObject(json)
            QrData(
                token = org.getString("token"),
                secondsLeft = org.optInt("seconds_left", 300)
            )
        } catch (e: Exception) {
            null
        }
    }

    data class QrData(val token: String, val secondsLeft: Int)
}
