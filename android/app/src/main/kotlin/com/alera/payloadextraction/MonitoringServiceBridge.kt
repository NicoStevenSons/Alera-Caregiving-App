package com.alera.payloadextraction

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

object MonitoringServiceBridge {

    private const val TAG =
        "AleraMonitoringBridge"

    fun start(
        context: Context
    ) {
        Log.d(
            TAG,
            "Requesting monitoring service start"
        )

        val intent =
            Intent(
                context,
                AleraMonitoringService::class.java
            ).apply {
                action =
                    AleraMonitoringService.ACTION_START
            }

        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.O
        ) {
            context.startForegroundService(
                intent
            )
        } else {
            context.startService(
                intent
            )
        }
    }

    fun stop(
        context: Context
    ) {
        Log.d(
            TAG,
            "Requesting monitoring service stop"
        )

        val intent =
            Intent(
                context,
                AleraMonitoringService::class.java
            ).apply {
                action =
                    AleraMonitoringService.ACTION_STOP
            }

        context.startService(
            intent
        )
    }
}