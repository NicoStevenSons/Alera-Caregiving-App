import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../config/app_config.dart';
import '../features/caregiver/data/auth/caregiver_token_store.dart';
import '../features/elderly/data/api/health_event_api_service.dart';
import 'fifo_upload_service.dart';
import 'upload_queue_service.dart';

const String aleraBackgroundSyncTask = 'aleraBackgroundSyncTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((
    String task,
    Map<String, dynamic>? inputData,
  ) async {
    WidgetsFlutterBinding.ensureInitialized();

    if (task != aleraBackgroundSyncTask) {
      return true;
    }

    try {
      final tokenStore = SecureCaregiverTokenStore();
      final session = await tokenStore.readSession();

      if (session == null ||
          session.type != SessionType.elderlyPatient ||
          session.patientId == null) {
        debugPrint('Background sync skipped: no valid patient session.');
        return true;
      }

      final patientId = session.patientId!;

      final uploadQueueService = UploadQueueService();

      final healthEventApiService = HealthEventApiService(
        baseUrl: AppConfig.backendBaseUrl,
        patientId: patientId,
      );

      final fifoUploadService = FifoUploadService(
        uploadQueueService: uploadQueueService,
        healthEventApiService: healthEventApiService,
        expectedPatientId: patientId,
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
