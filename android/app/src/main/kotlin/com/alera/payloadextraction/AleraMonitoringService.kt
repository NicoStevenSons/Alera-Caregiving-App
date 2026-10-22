package com.alera.payloadextraction

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

class AleraMonitoringService : Service() {

    companion object {
        private const val TAG =
            "AleraMonitoring"

        private const val HEARTBEAT_TAG =
            "AleraHeartbeat"

        private const val CHANNEL_ID =
            "alera_monitoring_channel"

        private const val CHANNEL_NAME =
            "Alera Monitoring"

        private const val NOTIFICATION_ID = 1001

        private const val HEARTBEAT_INTERVAL_SECONDS = 60L

        const val ACTION_START =
            "com.alera.payloadextraction.START_MONITORING"

        const val ACTION_STOP =
            "com.alera.payloadextraction.STOP_MONITORING"

        const val EXTRA_ACCESS_TOKEN =
            "com.alera.payloadextraction.ACCESS_TOKEN"

        const val EXTRA_PATIENT_ID =
            "com.alera.payloadextraction.PATIENT_ID"

        const val EXTRA_BASE_URL =
            "com.alera.payloadextraction.BASE_URL"
    }

    @Volatile
    private var accessToken: String? = null

    @Volatile
    private var patientId: String? = null

    @Volatile
    private var baseUrl: String? = null

    private val heartbeatExecutor =
        Executors.newSingleThreadScheduledExecutor()

    private var heartbeatFuture:
        ScheduledFuture<*>? = null

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

                stopHeartbeat()

                stopForeground(
                    STOP_FOREGROUND_REMOVE
                )

                stopSelf(startId)

                return START_NOT_STICKY
            }

            ACTION_START -> {
                if (
                    !canStartConnectedDeviceForegroundService()
                ) {
                    Log.w(
                        TAG,
                        "Monitoring service stopped: " +
                            "Bluetooth connect permission " +
                            "is not granted"
                    )

                    stopSelf(startId)

                    return START_NOT_STICKY
                }

                val newAccessToken =
                    intent.getStringExtra(
                        EXTRA_ACCESS_TOKEN
                    )

                val newPatientId =
                    intent.getStringExtra(
                        EXTRA_PATIENT_ID
                    )

                val newBaseUrl =
                    intent.getStringExtra(
                        EXTRA_BASE_URL
                    )

                if (
                    newAccessToken.isNullOrBlank() ||
                    newPatientId.isNullOrBlank() ||
                    newBaseUrl.isNullOrBlank()
                ) {
                    Log.e(
                        TAG,
                        "Monitoring service cannot start: " +
                            "authenticated patient session " +
                            "data is missing"
                    )

                    stopSelf(startId)

                    return START_NOT_STICKY
                }

                accessToken = newAccessToken
                patientId = newPatientId
                baseUrl = newBaseUrl

                Log.d(
                    TAG,
                    "Starting monitoring service"
                )

                startForeground(
                    NOTIFICATION_ID,
                    createNotification()
                )

                startHeartbeat()

                return START_REDELIVER_INTENT
            }

            else -> {
                Log.w(
                    TAG,
                    "Monitoring service received " +
                        "an invalid or empty start intent"
                )

                stopSelf(startId)

                return START_NOT_STICKY
            }
        }
    }

    private fun startHeartbeat() {
        val existing =
            heartbeatFuture

        if (
            existing != null &&
            !existing.isCancelled &&
            !existing.isDone
        ) {
            Log.d(
                HEARTBEAT_TAG,
                "Native phone heartbeat already running"
            )

            return
        }

        Log.d(
            HEARTBEAT_TAG,
            "Native phone heartbeat started"
        )

        heartbeatFuture =
            heartbeatExecutor.scheduleAtFixedRate(
                {
                    sendPhoneHeartbeat()
                },
                0L,
                HEARTBEAT_INTERVAL_SECONDS,
                TimeUnit.SECONDS
            )
    }

    private fun stopHeartbeat() {
        heartbeatFuture?.cancel(false)
        heartbeatFuture = null

        Log.d(
            HEARTBEAT_TAG,
            "Native phone heartbeat stopped"
        )
    }

    private fun sendPhoneHeartbeat() {
        val token =
            accessToken

        val currentPatientId =
            patientId

        val currentBaseUrl =
            baseUrl

        if (
            token.isNullOrBlank() ||
            currentPatientId.isNullOrBlank() ||
            currentBaseUrl.isNullOrBlank()
        ) {
            Log.w(
                HEARTBEAT_TAG,
                "Phone heartbeat skipped: " +
                    "patient session unavailable"
            )

            return
        }

        val batteryPercent =
            readBatteryPercent()

        val payload =
            JSONObject().apply {
                put(
                    "patient_id",
                    currentPatientId
                )

                put(
                    "device_type",
                    "PHONE"
                )

                put(
                    "connection_status",
                    "CONNECTED"
                )

                if (batteryPercent != null) {
                    put(
                        "battery_percent",
                        batteryPercent
                    )
                } else {
                    put(
                        "battery_percent",
                        JSONObject.NULL
                    )
                }

                put(
                    "reported_at",
                    Instant.now().toString()
                )
            }

        var connection:
            HttpURLConnection? = null

        try {
            val endpoint =
                currentBaseUrl
                    .trimEnd('/') +
                    "/api/v1/device-status"

            connection =
                URL(endpoint)
                    .openConnection() as HttpURLConnection

            connection.requestMethod =
                "POST"

            connection.connectTimeout =
                15_000

            connection.readTimeout =
                15_000

            connection.doOutput =
                true

            connection.setRequestProperty(
                "Authorization",
                "Bearer $token"
            )

            connection.setRequestProperty(
                "Content-Type",
                "application/json"
            )

            val body =
                payload
                    .toString()
                    .toByteArray(
                        Charsets.UTF_8
                    )

            connection.setFixedLengthStreamingMode(
                body.size
            )

            connection.outputStream.use {
                output ->
                output.write(body)
            }

            val statusCode =
                connection.responseCode

            Log.d(
                HEARTBEAT_TAG,
                "Phone heartbeat response: " +
                    statusCode +
                    ", battery=" +
                    (batteryPercent ?: "unknown") +
                    "%"
            )

            val stream =
                if (
                    statusCode in 200..299
                ) {
                    connection.inputStream
                } else {
                    connection.errorStream
                }

            stream?.use {
                it.readBytes()
            }

        } catch (exception: Exception) {
            Log.e(
                HEARTBEAT_TAG,
                "Phone heartbeat failed",
                exception
            )
        } finally {
            connection?.disconnect()
        }
    }

    private fun readBatteryPercent():
        Int? {

        val batteryIntent =
            registerReceiver(
                null,
                IntentFilter(
                    Intent.ACTION_BATTERY_CHANGED
                )
            ) ?: return null

        val level =
            batteryIntent.getIntExtra(
                BatteryManager.EXTRA_LEVEL,
                -1
            )

        val scale =
            batteryIntent.getIntExtra(
                BatteryManager.EXTRA_SCALE,
                -1
            )

        if (
            level < 0 ||
            scale <= 0
        ) {
            return null
        }

        return (
            level *
                100f /
                scale
            )
            .toInt()
            .coerceIn(
                0,
                100
            )
    }

    private fun canStartConnectedDeviceForegroundService():
        Boolean {

        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.S
        ) {
            return true
        }

        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED
    }

    override fun onDestroy() {
        stopHeartbeat()

        heartbeatExecutor.shutdownNow()

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

    private fun createNotification():
        Notification {

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