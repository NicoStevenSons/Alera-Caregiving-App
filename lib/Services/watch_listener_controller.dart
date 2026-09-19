import 'package:flutter/foundation.dart';
import 'dart:async';

import '../features/elderly/data/api/activity_data_api_service.dart';
import 'activity_data_mapper.dart';

import '../config/app_config.dart';
import '../models/device_status_data.dart';
import '../models/heart_rate_data.dart';
import '../models/sleep_data.dart';
import '../models/spo2_data.dart';
import '../models/steps_data.dart';
import 'fifo_upload_service.dart';
import '../features/elderly/data/api/health_event_api_service.dart';
import 'health_event_mapper.dart';
import 'upload_queue_service.dart';
import 'watch_payload_service.dart';

class WatchListenerController {
  final WatchPayloadService watchPayloadService;
  final UploadQueueService uploadQueueService;
  final HealthEventApiService healthEventApiService;
  final FifoUploadService fifoUploadService;
  final ActivityDataApiService activityDataApiService;

  final void Function(HeartRateData data) onHeartRateUpdated;
  final void Function(SpO2Data data) onSpO2Updated;
  final void Function(StepsData data) onStepsUpdated;
  final void Function(DeviceStatusData data) onDeviceStatusUpdated;
  final void Function(SleepData data) onSleepUpdated;
  

  WatchListenerController({
    required this.watchPayloadService,
    required this.uploadQueueService,
    required this.healthEventApiService,
    required this.fifoUploadService,
    required this.onHeartRateUpdated,
    required this.onSpO2Updated,
    required this.onStepsUpdated,
    required this.onDeviceStatusUpdated,
    required this.onSleepUpdated,
    required this.activityDataApiService,
  });

  void start() {
    watchPayloadService.startListening(
      onHeartRateReceived: _handleHeartRate,

      onSpO2Received: _handleSpO2,

      onStepsReceived: (StepsData data) {
        unawaited(
        _handleSteps(data),
        );
      },

      onDeviceStatusReceived: (DeviceStatusData data) {
        onDeviceStatusUpdated(data);
      },

      onSleepReceived: (SleepData data) {
        unawaited(
        _handleSleep(data),
        );
      },

      onError: (Object error) {
        debugPrint('Payload listener error: $error');
      },
    );
  }

  Future<void> _handleSteps(
  StepsData data,
) async {
  onStepsUpdated(data);

  if (!AppConfig.enableBackend) {
    return;
  }

  final Map<String, dynamic>
      backendPayload =
      ActivityDataMapper.mapSteps(
        patientId:
            activityDataApiService.patientId,
        data: data,
      );

  debugPrint(
    'Uploading steps activity: '
    'total=${data.totalSteps}, '
    'sessions=${data.sessions.length}',
  );

  final bool uploaded =
      await activityDataApiService
          .sendActivityData(
            backendPayload,
          );

  if (uploaded) {
    debugPrint(
      'Steps activity uploaded successfully.',
    );
  } else {
    debugPrint(
      'Steps activity upload failed. '
      'Next refresh will retry '
      'with the latest daily snapshot.',
    );
  }
}

  Future<void> _handleSleep(
  SleepData data,
) async {
  onSleepUpdated(data);

  if (!AppConfig.enableBackend) {
    return;
  }

  if (data.sessions.isEmpty) {
    debugPrint(
      'No sleep sessions to upload.',
    );
    return;
  }

  final List<Map<String, dynamic>>
      payloads =
      ActivityDataMapper.mapSleep(
        patientId:
            activityDataApiService.patientId,
        data: data,
      );

  debugPrint(
    'Uploading sleep activity: '
    '${data.sessions.length} sessions '
    'across ${payloads.length} day(s).',
  );

  for (final payload in payloads) {
    final bool uploaded =
        await activityDataApiService
            .sendActivityData(
              payload,
            );

    if (uploaded) {
      debugPrint(
        'Sleep activity uploaded: '
        '${payload['activity_date']}',
      );
    } else {
      debugPrint(
        'Sleep activity upload failed: '
        '${payload['activity_date']}',
      );
    }
  }
}

  Future<void> _handleHeartRate(HeartRateData data) async {
    onHeartRateUpdated(data);

    final int? bpm = data.bpm;
    final String? measuredAt = data.measuredAt;

    if (bpm == null || bpm <= 0 || measuredAt == null || data.status != 1) {
      debugPrint(
        'Heart-rate reading not queued: '
        'invalid or still measuring.',
      );
      return;
    }

    final Map<String, dynamic> backendPayload = HealthEventMapper.mapHeartRate(
      patientId: healthEventApiService.patientId,
      heartRateBpm: bpm,
      recordedAt: measuredAt,
      rawPayload: data.toJson(),
    );

    final int localId = await uploadQueueService.enqueue(
      metricType: 'HEART_RATE',
      payload: backendPayload,
    );

    debugPrint('HR saved locally. Queue ID: $localId');

    if (AppConfig.enableBackend) {
      await fifoUploadService.processQueue();
    }
  }

  Future<void> _handleSpO2(SpO2Data data) async {
    onSpO2Updated(data);

    final double? percent = data.percent;
    final String? measuredAt = data.measuredAt;

    if (percent == null ||
        percent <= 0 ||
        measuredAt == null ||
        data.status != 2) {
      final int localId = await uploadQueueService.enqueue(
        metricType: 'SPO2',
        payload: data.toJson(),
        queueStatus: 'FAILED_MEASUREMENT',
        lastError:
            'SpO2 measurement failed or incomplete. '
            'status=${data.status}',
      );

      debugPrint(
        'Failed SpO₂ reading saved locally. '
        'Queue ID: $localId, '
        'status: ${data.status}',
      );

      return;
    }

    final Map<String, dynamic> backendPayload = HealthEventMapper.mapSpO2(
      patientId: healthEventApiService.patientId,
      spo2Percent: percent,
      recordedAt: measuredAt,
      rawPayload: data.toJson(),
    );

    final int localId = await uploadQueueService.enqueue(
      metricType: 'SPO2',
      payload: backendPayload,
    );

    debugPrint(
      'Valid SpO₂ saved locally. '
      'Queue ID: $localId',
    );

    if (AppConfig.enableBackend) {
      await fifoUploadService.processQueue();
    }
  }
}
