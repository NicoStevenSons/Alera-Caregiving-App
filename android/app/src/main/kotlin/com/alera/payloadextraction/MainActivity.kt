package com.alera.payloadextraction

import android.os.Bundle
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission

import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

import kotlinx.coroutines.launch

import androidx.health.connect.client.records.StepsRecord
import com.alera.payloadextraction.health.StepsDataReader
import androidx.health.connect.client.records.SleepSessionRecord
import com.alera.payloadextraction.health.SleepDataReader

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val PAYLOAD_CHANNEL =
            "com.alera.payloadextraction/payloads"

        private const val WATCH_STATUS_CHANNEL =
            "com.alera.payloadextraction/watch_status"
    }

    private lateinit var healthConnectClient:HealthConnectClient
    private lateinit var stepsDataReader: StepsDataReader
    private lateinit var sleepDataReader: SleepDataReader
    private val healthPermissions = setOf(HealthPermission.getReadPermission(StepsRecord::class),HealthPermission.getReadPermission(SleepSessionRecord::class))

    private val healthPermissionLauncher = registerForActivityResult(PermissionController.createRequestPermissionResultContract()
    ) { grantedPermissions: Set<String> ->

        Log.d(
            "AleraHealthConnect",
            "Granted permissions: $grantedPermissions"
        )

        val stepsPermission =
            HealthPermission.getReadPermission(
                StepsRecord::class
            )

        val sleepPermission =
            HealthPermission.getReadPermission(
                SleepSessionRecord::class
            )

        val stepsGranted =
            grantedPermissions.contains(
                stepsPermission
            )

        val sleepGranted =
            grantedPermissions.contains(
                sleepPermission
            )

        Log.d(
            "AleraHealthConnect",
            "Steps granted: $stepsGranted, " +
                "Sleep granted: $sleepGranted"
        )

        if (stepsGranted) {
            readAndSendTodaySteps()
        }

        if (sleepGranted) {
            readAndSendRecentSleep()
        }

        if (!stepsGranted || !sleepGranted) {
            Log.w(
                "AleraHealthConnect",
                "One or more Health Connect permissions denied"
            )
        }
    }


private fun refreshSteps() {
    Log.d(
        "AleraHealthConnect",
        "Refreshing Health Connect steps"
    )

    readAndSendTodaySteps()
}//for testing

    override fun onCreate(
    savedInstanceState: Bundle?
) {
    super.onCreate(savedInstanceState)
    healthConnectClient = HealthConnectClient.getOrCreate(this)
    stepsDataReader = StepsDataReader(this)
    sleepDataReader = SleepDataReader(this)
    requestHealthPermissions()
}

    private fun requestHealthPermissions() {
    lifecycleScope.launch {
        val grantedPermissions =
            healthConnectClient
                .permissionController
                .getGrantedPermissions()

        val stepsPermission =
            HealthPermission.getReadPermission(
                StepsRecord::class
            )

        val sleepPermission =
            HealthPermission.getReadPermission(
                SleepSessionRecord::class
            )

        val stepsGranted =
            grantedPermissions.contains(
                stepsPermission
            )

        val sleepGranted =
            grantedPermissions.contains(
                sleepPermission
            )

        Log.d(
            "AleraHealthConnect",
            "Existing permissions: " +
                "steps=$stepsGranted, " +
                "sleep=$sleepGranted"
        )

        if (stepsGranted) {
            readAndSendTodaySteps()
        }

        if (sleepGranted) {
            readAndSendRecentSleep()
        }

        val missingPermissions =
            healthPermissions.filterNot {
                grantedPermissions.contains(it)
            }.toSet()

        if (missingPermissions.isNotEmpty()) {
            healthPermissionLauncher.launch(
                missingPermissions
            )
        }
    }
}

    private fun readAndSendTodaySteps() {
    lifecycleScope.launch {
        try {
            val sessions =
                stepsDataReader.readAllStepSessions()

                Log.d(
                "AleraHealthConnect",
                "Step sessions found: ${sessions.size}"
                )

                sessions.forEach { session ->
                Log.d(
                    "AleraHealthConnect",
                    "Steps: ${session.stepCount}, " +
                    "start=${session.startTime}, " +
                    "end=${session.endTime}"
                    )
                        }

            val sessionsJson =
                sessions.joinToString(
                    separator = ",",
                    prefix = "[",
                    postfix = "]"
                ) { session ->
                    """
                    {
                      "step_count": ${session.stepCount},
                      "start_time": "${session.startTime}",
                      "end_time": "${session.endTime}"
                    }
                    """.trimIndent()
                }

            val payload =
                """
                {
                  "event_type": "steps",
                  "sessions": $sessionsJson
                }
                """.trimIndent()

            Log.d(
                "AleraHealthConnect",
                "Steps payload: $payload"
            )

            PayloadEventBridge.sendPayload(payload)
        } catch (exception: Exception) {
            Log.e(
                "AleraHealthConnect",
                "Failed to read step sessions",
                exception
            )
        }
    }
}
    private fun readAndSendRecentSleep() {
    lifecycleScope.launch {
        try {
            val sessions =
                sleepDataReader.readRecentSleepSessions()

            Log.d(
                "AleraHealthConnect",
                "Sleep sessions found: ${sessions.size}"
            )

            val sessionsJson =
                sessions.joinToString(
                    separator = ",",
                    prefix = "[",
                    postfix = "]"
                ) { session ->

                    val stagesJson =
                        session.stages.joinToString(
                            separator = ",",
                            prefix = "[",
                            postfix = "]"
                        ) { stage ->
                            """
                            {
                              "stage": ${stage.stage},
                              "start_time": "${stage.startTime}",
                              "end_time": "${stage.endTime}"
                            }
                            """.trimIndent()
                        }

                    """
                    {
                      "start_time": "${session.startTime}",
                      "end_time": "${session.endTime}",
                      "title": ${session.title?.let { "\"$it\"" } ?: "null"},
                      "notes": ${session.notes?.let { "\"$it\"" } ?: "null"},
                      "stages": $stagesJson
                    }
                    """.trimIndent()
                }

            val payload =
                """
                {
                  "event_type": "sleep",
                  "sessions": $sessionsJson
                }
                """.trimIndent()

            Log.d(
                "AleraHealthConnect",
                "Sleep payload: $payload"
            )

            PayloadEventBridge.sendPayload(
                payload
            )
        } catch (exception: Exception) {
            Log.e(
                "AleraHealthConnect",
                "Failed to read sleep sessions",
                exception
            )
        }
    }
}

override fun configureFlutterEngine(
    flutterEngine: FlutterEngine
) {
    super.configureFlutterEngine(
        flutterEngine
    )

    EventChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        PAYLOAD_CHANNEL
    ).setStreamHandler(
        object : EventChannel.StreamHandler {

            override fun onListen(
                arguments: Any?,
                events: EventChannel.EventSink?
            ) {
                Log.d(
                    "AleraFlutterBridge",
                    "Flutter started listening"
                )

                PayloadEventBridge.attachSink(events)

                lifecycleScope.launch {
                    val grantedPermissions =
                        healthConnectClient
                            .permissionController
                            .getGrantedPermissions()

                    val stepsPermission =
                        HealthPermission.getReadPermission(
                            StepsRecord::class
                        )

                    val sleepPermission =
                        HealthPermission.getReadPermission(
                            SleepSessionRecord::class
                        )

                    if (
                        stepsPermission in grantedPermissions
                    ) {
                        Log.d(
                            "AleraHealthConnect",
                            "Flutter listener ready - refreshing steps"
                        )

                        readAndSendTodaySteps()
                    }

                    if (
                        sleepPermission in grantedPermissions
                    ) {
                        Log.d(
                            "AleraHealthConnect",
                            "Flutter listener ready - refreshing sleep"
                        )

                        readAndSendRecentSleep()
                    }
                }
            }

            override fun onCancel(
                arguments: Any?
            ) {
                Log.d(
                    "AleraFlutterBridge",
                    "Flutter stopped listening"
                )

                PayloadEventBridge.attachSink(
                    null
                )
            }
        }
    )

    MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        WATCH_STATUS_CHANNEL
    ).setMethodCallHandler { call, result ->

        when (call.method) {

            "requestWatchStatus" -> {
                val requester =
                    WatchStatusRequester(
                        applicationContext
                    )

                requester.requestStatus()

                result.success(true)
            }

            else -> {
                result.notImplemented()
            }
        }
    }
}
}