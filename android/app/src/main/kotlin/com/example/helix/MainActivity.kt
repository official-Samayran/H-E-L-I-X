package com.example.helix

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.view.Surface
import android.os.Vibrator
import android.os.VibrationEffect
import android.media.projection.MediaProjectionManager
import android.content.Intent

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.helix/secure"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setSecure") {
                val secure = call.argument<Boolean>("secure") ?: false
                if (secure) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            } else if (call.method == "setFrameRate") {
                val lock = call.argument<Boolean>("lock") ?: false
                val attrs = window.attributes
                if (lock) {
                    attrs.preferredRefreshRate = 144f
                } else {
                    attrs.preferredRefreshRate = 0f
                }
                window.attributes = attrs
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.helix/haptics").setMethodCallHandler { call, result ->
            if (call.method == "vibrateWaveform") {
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (vibrator.hasVibrator()) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val effect = VibrationEffect.createWaveform(longArrayOf(0, 10), intArrayOf(0, 100), -1)
                        vibrator.vibrate(effect)
                    } else {
                        @Suppress("DEPRECATION")
                        vibrator.vibrate(10)
                    }
                    result.success(null)
                } else {
                    result.error("UNAVAILABLE", "Vibrator not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.helix/screenshare").setMethodCallHandler { call, result ->
            if (call.method == "startScreenShare") {
                val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                startActivityForResult(mediaProjectionManager.createScreenCaptureIntent(), 1000)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val bgChannel = NotificationChannel(
                "helix_bg_v2",
                "Helix Background Service",
                NotificationManager.IMPORTANCE_LOW
            )
            bgChannel.description = "This channel is used for important notifications."

            val statusChannel = NotificationChannel(
                "helix_status",
                "PC Status Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            statusChannel.description = "PC Status Notifications"

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(bgChannel)
            notificationManager.createNotificationChannel(statusChannel)
        }
    }
}
