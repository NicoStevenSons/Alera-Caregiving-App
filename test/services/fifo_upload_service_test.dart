import 'dart:convert';

import 'package:alera/Services/fifo_upload_service.dart';
import 'package:alera/Services/upload_queue_service.dart';
import 'package:alera/features/elderly/data/api/health_event_api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const patientA = 'a076ecdb-ae38-4f84-b490-e714977027ee';
const patientB = 'b176ecdb-ae38-4f84-b490-e714977027ee';

class FakeUploadQueueService extends UploadQueueService {
  FakeUploadQueueService(this.rows);

  final List<Map<String, dynamic>> rows;

  final List<int> deletedIds = [];
  final List<Map<String, Object?>> temporaryFailures = [];

  @override
  Future<Map<String, dynamic>?> getOldestPending() async {
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  @override
  Future<void> deleteById(int id) async {
    deletedIds.add(id);
    rows.removeWhere((row) => row['id'] == id);
  }

  @override
  Future<void> updateTemporaryFailure({
    required int id,
    required String error,
  }) async {
    temporaryFailures.add({'id': id, 'error': error});
  }
}

class FakeHealthEventApiService extends HealthEventApiService {
  FakeHealthEventApiService({
    required super.patientId,
    required this.responseStatus,
  }) : super(baseUrl: 'https://example.test');

  final int responseStatus;

  int callCount = 0;
  Map<String, dynamic>? lastPayload;
  String? lastAccessToken;

  @override
  Future<http.Response> sendHealthEvent(
    Map<String, dynamic> payload, {
    required String accessToken,
  }) async {
    callCount++;
    lastPayload = Map<String, dynamic>.from(payload);
    lastAccessToken = accessToken;

    return http.Response('{}', responseStatus);
  }
}

Map<String, dynamic> queueRow({required String patientId, int id = 1}) {
  return {
    'id': id,
    'retry_count': 0,
    'payload_json': jsonEncode({
      'patient_id': patientId,
      'metric_type': 'HEART_RATE',
      'numeric_value': 78,
    }),
  };
}

void setPatientSession({
  required String patientId,
  String token = 'patient-token',
}) {
  FlutterSecureStorage.setMockInitialValues({
    'alera_session': jsonEncode({
      'token': token,
      'type': 'elderly_patient',
      'patient_id': patientId,
    }),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'authenticated patient payload uses bearer token and deletes successful upload',
    () async {
      setPatientSession(patientId: patientA);

      final queue = FakeUploadQueueService([queueRow(patientId: patientA)]);

      final api = FakeHealthEventApiService(
        patientId: patientA,
        responseStatus: 200,
      );

      final uploader = FifoUploadService(
        uploadQueueService: queue,
        healthEventApiService: api,
        expectedPatientId: patientA,
      );

      await uploader.processQueue();

      expect(api.callCount, 1);
      expect(api.lastPayload?['patient_id'], patientA);
      expect(api.lastAccessToken, 'patient-token');

      expect(queue.deletedIds, [1]);
      expect(queue.rows, isEmpty);
    },
  );

  test('server failure preserves queued patient event', () async {
    setPatientSession(patientId: patientA);

    final queue = FakeUploadQueueService([queueRow(patientId: patientA)]);

    final api = FakeHealthEventApiService(
      patientId: patientA,
      responseStatus: 503,
    );

    final uploader = FifoUploadService(
      uploadQueueService: queue,
      healthEventApiService: api,
      expectedPatientId: patientA,
    );

    await uploader.processQueue();

    expect(api.callCount, 1);

    expect(queue.deletedIds, isEmpty);
    expect(queue.rows, hasLength(1));

    expect(queue.temporaryFailures, hasLength(1));
    expect(queue.temporaryFailures.first['id'], 1);
  });

  test(
    'queued event for another patient is preserved and never uploaded',
    () async {
      setPatientSession(patientId: patientA);

      final queue = FakeUploadQueueService([queueRow(patientId: patientB)]);

      final api = FakeHealthEventApiService(
        patientId: patientA,
        responseStatus: 200,
      );

      final uploader = FifoUploadService(
        uploadQueueService: queue,
        healthEventApiService: api,
        expectedPatientId: patientA,
      );

      await uploader.processQueue();

      expect(api.callCount, 0);

      expect(queue.deletedIds, isEmpty);
      expect(queue.rows, hasLength(1));
      expect(
        jsonDecode(queue.rows.first['payload_json'] as String)['patient_id'],
        patientB,
      );
    },
  );
}
