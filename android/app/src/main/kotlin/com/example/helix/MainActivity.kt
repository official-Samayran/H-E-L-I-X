package com.example.helix

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
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
