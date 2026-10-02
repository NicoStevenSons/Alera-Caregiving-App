package com.alera.payloadextraction

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class AleraMonitoringService : Service() {

    companion object {
        private const val TAG = "AleraMonitoring"

        private const val CHANNEL_ID =
            "alera_monitoring_channel"

        private const val CHANNEL_NAME =
            "Alera Monitoring"

        private const val NOTIFICATION_ID = 1001

        const val ACTION_START =
            "com.alera.payloadextraction.START_MONITORING"

        const val ACTION_STOP =
            "com.alera.payloadextraction.STOP_MONITORING"
    }

    override fun onCreate() {
        super.onCreate()

        Log.d(
            TAG,
            "Monitoring service created"
        )

        createNotificationChannel()
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        when (intent?.action) {

            ACTION_STOP -> {
                Log.d(
                    TAG,
                    "Stopping monitoring service"
                )

                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()

                return START_NOT_STICKY
            }

            ACTION_START,
            null -> {
                Log.d(
                    TAG,
                    "Starting monitoring service"
                )

                startForeground(
                    NOTIFICATION_ID,
                    createNotification()
                )
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        Log.d(
            TAG,
            "Monitoring service destroyed"
        )

        super.onDestroy()
    }

    override fun onBind(
        intent: Intent?
    ): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.O
        ) {
            val channel =
                NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_LOW
                )

            channel.description =
                "Keeps Alera health monitoring active"

            val manager =
                getSystemService(
                    NotificationManager::class.java
                )

            manager.createNotificationChannel(
                channel
            )
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(
            this,
            CHANNEL_ID
        )
            .setContentTitle(
                "Alera monitoring active"
            )
            .setContentText(
                "Monitoring smartwatch and device status"
            )
            .setSmallIcon(
                R.mipmap.ic_launcher
            )
            .setOngoing(true)
            .setPriority(
                NotificationCompat.PRIORITY_LOW
            )
            .build()
    }
}