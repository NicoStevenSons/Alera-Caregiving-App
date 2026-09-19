package com.alera.payloadextraction.health

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.temporal.ChronoUnit

data class SleepStageData(
    val stage: Int,
    val startTime: Instant,
    val endTime: Instant
)

data class SleepSessionData(
    val startTime: Instant,
    val endTime: Instant,
    val title: String?,
    val notes: String?,
    val stages: List<SleepStageData>
)

class SleepDataReader(
    context: Context
) {
    private val healthConnectClient =
        HealthConnectClient.getOrCreate(context)

    suspend fun readRecentSleepSessions():
        List<SleepSessionData> {

        val now = Instant.now()
        val startTime = now.minus(7, ChronoUnit.DAYS)

        val response =
            healthConnectClient.readRecords(
                ReadRecordsRequest(
                    recordType =
                        SleepSessionRecord::class,
                    timeRangeFilter =
                        TimeRangeFilter.between(
                                startTime,
                                now
                                 ),
                    ascendingOrder = false
                )
            )

        return response.records.map { record ->
            SleepSessionData(
                startTime = record.startTime,
                endTime = record.endTime,
                title = record.title,
                notes = record.notes,
                stages = record.stages.map { stage ->
                    SleepStageData(
                        stage = stage.stage,
                        startTime = stage.startTime,
                        endTime = stage.endTime
                    )
                }
            )
        }
    }
}