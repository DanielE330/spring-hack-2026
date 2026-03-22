package com.example.entry_point

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews

/**
 * Android Home Screen Widget — показывает QR-пропуск.
 *
 * Обновляется каждые 5 минут (updatePeriodMillis=300000).
 * При тапе открывает QrSecureActivity с FLAG_SECURE.
 */
class QrPassWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "QrPassWidget"
        private const val PREFS_NAME = "FlutterSecureStorage"
        private const val KEY_DEVICE_CODE = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_device_code"
        private const val BASE_URL = "http://194.113.106.32"
        private const val QR_GENERATE_URL = "$BASE_URL/qr/generate/"

        // Executor вынесен в companion object, чтобы не создавать новый при каждом обновлении виджета
        private val executor = java.util.concurrent.Executors.newSingleThreadExecutor()

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

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            // Сначала показываем «Обновление...» в виде bitmap-заглушки
            val loadingViews = RemoteViews(context.packageName, R.layout.widget_qr_pass).apply {
                setImageViewBitmap(R.id.widget_image, WidgetBitmapRenderer.renderStatus("Обновление..."))
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

        val bitmap = try {
            val deviceCode = getDeviceCode(context)
            if (deviceCode.isNullOrEmpty()) {
                WidgetBitmapRenderer.renderStatus("Войдите в приложение")
            } else {
                val qrData = fetchQrToken(deviceCode)
                if (qrData != null) {
                    // Рисуем полный визуал: кольцо + QR + текст таймера
                    WidgetBitmapRenderer.render(
                        qrToken = qrData.token,
                        secondsLeft = qrData.secondsLeft
                    )
                } else {
                    WidgetBitmapRenderer.renderStatus("Ошибка загрузки")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "updateWidget exception", e)
            WidgetBitmapRenderer.renderStatus("Нет соединения")
        }

        views.setImageViewBitmap(R.id.widget_image, bitmap)

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
     * Использует applicationContext для надёжности.
     */
    private fun getDeviceCode(context: Context): String? {
        return try {
            val appCtx = context.applicationContext
            val masterKey = androidx.security.crypto.MasterKey.Builder(appCtx)
                .setKeyScheme(androidx.security.crypto.MasterKey.KeyScheme.AES256_GCM)
                .build()
            val prefs = androidx.security.crypto.EncryptedSharedPreferences.create(
                appCtx,
                PREFS_NAME,
                masterKey,
                androidx.security.crypto.EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                androidx.security.crypto.EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
            val code = prefs.getString(KEY_DEVICE_CODE, null)
            if (code.isNullOrEmpty()) {
                Log.w(TAG, "device_code отсутствует — пользователь не авторизован")
            }
            code
        } catch (e: Exception) {
            Log.e(TAG, "Ошибка чтения EncryptedSharedPreferences", e)
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

            val code = conn.responseCode
            Log.d(TAG, "qr/generate/ → HTTP $code")
            if (code == 200) {
                val response = conn.inputStream.bufferedReader().readText()
                parseQrResponse(response)
            } else {
                Log.e(TAG, "Сервер вернул $code")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Ошибка HTTP-запроса", e)
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
