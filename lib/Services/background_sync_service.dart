import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../config/app_config.dart';
import 'fifo_upload_service.dart';
import '../features/elderly/data/api/health_event_api_service.dart';
import 'upload_queue_service.dart';

const String aleraBackgroundSyncTask = 'aleraBackgroundSyncTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((
    String task,
    Map<String, dynamic>? inputData,
  ) async {
    debugPrint('Alera background task started: $task');

    if (task != aleraBackgroundSyncTask) {
      return true;
    }

    try {
      final UploadQueueService uploadQueueService = UploadQueueService();

      final HealthEventApiService healthEventApiService = HealthEventApiService(
        baseUrl: AppConfig.backendBaseUrl,
        patientId: AppConfig.testPatientId,
      );

      final FifoUploadService fifoUploadService = FifoUploadService(
        uploadQueueService: uploadQueueService,
        healthEventApiService: healthEventApiService,
      );

      await fifoUploadService.processQueue();

      debugPrint('Alera background queue sync finished.');

      return true;
    } catch (error) {
      debugPrint('Alera background sync error: $error');

      return false;
    }
  });
}
