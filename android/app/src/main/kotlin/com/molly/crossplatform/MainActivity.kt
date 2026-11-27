package com.molly.crossplatform

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val ABRIDGE_CHANNEL = "com.molly.crossplatform/abridge"
    private val BG_CHANNEL = "com.molly.crossplatform/background_service"

    private var wakeLock: PowerManager.WakeLock? = null
    private val ONGOING_TASK_NOTIFICATION_ID = 1001

    private val CHANNEL_TASKS = "molly_background_tasks"
    private val CHANNEL_ALERTS = "molly_agent_alerts"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        initNotificationChannels()

        // Channel ABridge
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ABRIDGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    val info = mapOf(
                        "model" to Build.MODEL,
                        "manufacturer" to Build.MANUFACTURER,
                        "brand" to Build.BRAND,
                        "device" to Build.DEVICE,
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "release" to Build.VERSION.RELEASE,
                        "platform" to "Android"
                    )
                    result.success(info)
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            result.success(true)
                        } else {
                            result.error("NOT_FOUND", "Aplikasi dengan package $packageName tidak ditemukan.", null)
                        }
                    } else {
                        result.error("INVALID_ARG", "Package name kosong.", null)
                    }
                }
                "vibrate" -> {
                    val durationMs = call.argument<Int>("durationMs")?.toLong() ?: 100L
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                            val vibrator = vibratorManager.defaultVibrator
                            vibrator.vibrate(VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE))
                        } else {
                            @Suppress("DEPRECATION")
                            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                vibrator.vibrate(VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE))
                            } else {
                                vibrator.vibrate(durationMs)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "checkAccessibility" -> {
                    val enabled = Settings.Secure.getString(
                        contentResolver,
                        Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                    ) ?: ""
                    result.success(mapOf("enabledServices" to enabled))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Channel Background Task & Notifications
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BG_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundTask" -> {
                    val title = call.argument<String>("title") ?: "Molly AI: Agen sedang memproses task..."
                    val content = call.argument<String>("content") ?: "Task sedang dieksekusi di latar belakang."
                    acquireWakeLock("AgentTask")
                    showOngoingTaskNotification(title, content)
                    result.success(true)
                }
                "stopBackgroundTask" -> {
                    releaseWakeLock()
                    hideOngoingTaskNotification()
                    result.success(true)
                }
                "showNotification" -> {
                    val type = call.argument<String>("type") ?: "info"
                    val title = call.argument<String>("title") ?: "Molly AI"
                    val body = call.argument<String>("body") ?: ""
                    val id = call.argument<Int>("id") ?: when (type) {
                        "confirmation" -> 2001
                        "success" -> 2002
                        "failed" -> 2003
                        else -> 2000
                    }
                    showAlertNotification(id, type, title, body)
                    result.success(true)
                }
                "checkBatteryOptimizations" -> {
                    val isIgnored = isIgnoringBatteryOptimizations()
                    result.success(isIgnored)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    requestIgnoreBatteryOptimizations()
                    result.success(true)
                }
                "requestPermissions" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
                    }
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val taskChannel = NotificationChannel(
                CHANNEL_TASKS,
                "Molly Task Berjalan (Latar Belakang)",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifikasi status task agen AI saat aplikasi di-minimize"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(taskChannel)

            val alertChannel = NotificationChannel(
                CHANNEL_ALERTS,
                "Molly Konfirmasi & Hasil Task",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi konfirmasi, kesuksesan, dan kegagalan task agen AI"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 150, 300)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(alertChannel)
        }
    }

    private fun getAppIcon(): Int {
        return if (applicationInfo.icon != 0) applicationInfo.icon else android.R.drawable.ic_dialog_info
    }

    private fun getLaunchPendingIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(this, 0, intent, flags)
    }

    private fun showOngoingTaskNotification(title: String, content: String) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, CHANNEL_TASKS)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

            builder.setContentTitle(title)
                .setContentText(content)
                .setSmallIcon(getAppIcon())
                .setContentIntent(getLaunchPendingIntent())
                .setOngoing(true)
                .setAutoCancel(false)

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                @Suppress("DEPRECATION")
                builder.setPriority(Notification.PRIORITY_LOW)
            }

            notificationManager.notify(ONGOING_TASK_NOTIFICATION_ID, builder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun hideOngoingTaskNotification() {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(ONGOING_TASK_NOTIFICATION_ID)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showAlertNotification(id: Int, type: String, title: String, body: String) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, CHANNEL_ALERTS)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

            builder.setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(getAppIcon())
                .setContentIntent(getLaunchPendingIntent())
                .setAutoCancel(true)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                builder.setStyle(Notification.BigTextStyle().bigText(body))
            }

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                @Suppress("DEPRECATION")
                builder.setPriority(Notification.PRIORITY_HIGH)
                @Suppress("DEPRECATION")
                builder.setDefaults(Notification.DEFAULT_ALL)
            }

            notificationManager.notify(id, builder.build())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun acquireWakeLock(tag: String) {
        try {
            if (wakeLock == null) {
                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "MollyCrossPlatform::$tag")
                wakeLock?.setReferenceCounted(false)
            }
            if (wakeLock?.isHeld == false) {
                wakeLock?.acquire(30 * 60 * 1000L) // 30 minutes max
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
            } catch (e: Exception) {
                try {
                    val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(fallbackIntent)
                } catch (e2: Exception) {
                    e2.printStackTrace()
                }
            }
        }
    }
}
