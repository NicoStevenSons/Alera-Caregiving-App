import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../features/caregiver/data/auth/caregiver_token_store.dart';
import '../features/elderly/data/api/health_event_api_service.dart';
import 'upload_queue_service.dart';

class FifoUploadService {
  final UploadQueueService uploadQueueService;
  final HealthEventApiService healthEventApiService;
  final String expectedPatientId;

  bool _isProcessing = false;

  FifoUploadService({
    required this.uploadQueueService,
    required this.healthEventApiService,
    required this.expectedPatientId,
  });

  Future<void> processQueue() async {
    if (_isProcessing) {
      debugPrint('FIFO uploader already running.');
      return;
    }

    _isProcessing = true;

    try {
      final tokenStore = SecureCaregiverTokenStore();
      final initialSession = await tokenStore.readSession();

      if (initialSession == null ||
          initialSession.type != SessionType.elderlyPatient ||
          initialSession.patientId != expectedPatientId) {
        debugPrint('FIFO stopped: invalid patient session.');
        return;
      }

      final expectedToken = initialSession.token;

      while (true) {
        final Map<String, dynamic>? row = await uploadQueueService
            .getOldestPending();

        if (row == null) {
          debugPrint('FIFO queue is empty.');
          break;
        }

        final int id = row['id'] as int;

        final int retryCount = row['retry_count'] as int;

        final String payloadJson = row['payload_json'] as String;

        final Map<String, dynamic> payload = Map<String, dynamic>.from(
          jsonDecode(payloadJson),
        );

        final queuedPatientId = payload['patient_id'];

        if (queuedPatientId is! String ||
            queuedPatientId.toLowerCase() != expectedPatientId.toLowerCase()) {
          debugPrint('Queue ID $id blocked: patient identity mismatch.');

          //preserve the record, never upload another patients data
          break;
        }

        final currentSession = await tokenStore.readSession();

        if (currentSession == null ||
            currentSession.type != SessionType.elderlyPatient ||
            currentSession.patientId != expectedPatientId ||
            currentSession.token != expectedToken) {
          debugPrint('FIFO stopped: patient session changed or ended.');
          break;
        }

        debugPrint('Uploading Queue ID: $id');

        try {
          final http.Response response = await healthEventApiService
              .sendHealthEvent(payload, accessToken: currentSession.token);

          final int statusCode = response.statusCode;

          if (statusCode >= 200 && statusCode < 300) {
            await uploadQueueService.deleteById(id);

            debugPrint(
              'Queue ID $id uploaded '
              'successfully and deleted.',
            );

            continue;
          }

          if (statusCode == 422) {
            final int newRetryCount = retryCount + 1;

            if (newRetryCount >= 3) {
              await uploadQueueService.moveToDeadLetter(
                id: id,
                retryCount: newRetryCount,
                error: 'HTTP 422: ${response.body}',
              );

              debugPrint(
                'Queue ID $id moved '
                'to DEAD_LETTER after '
                '$newRetryCount rejected attempts.',
              );

              // continue with next FIFO item.
              continue;
            }

            await uploadQueueService.updateFailure(
              id: id,
              retryCount: newRetryCount,
              error: 'HTTP 422: ${response.body}',
            );

            debugPrint(
              'Queue ID $id rejected '
              'with 422. '
              'Attempt $newRetryCount/3.',
            );
            break;
          }

          // SERVER-SIDE TEMPORARY FAILURE
          if (statusCode >= 500) {
            await uploadQueueService.updateTemporaryFailure(
              id: id,
              error:
                  'HTTP $statusCode: '
                  '${response.body}',
            );

            debugPrint(
              'Queue ID $id kept locally. '
              'Server error $statusCode.',
            );

            break;
          }

          // OTHER HTTP ERRORS
          await uploadQueueService.updateTemporaryFailure(
            id: id,
            error:
                'HTTP $statusCode: '
                '${response.body}',
          );

          debugPrint(
            'Queue ID $id kept locally. '
            'Unexpected HTTP status: '
            '$statusCode.',
          );

          break;
        } on TimeoutException catch (error) {
          await uploadQueueService.updateTemporaryFailure(
            id: id,
            error: 'Timeout: $error',
          );

          debugPrint(
            'Queue ID $id kept locally '
            'because upload timed out.',
          );

          break;
        } on SocketException catch (error) {
          await uploadQueueService.updateTemporaryFailure(
            id: id,
            error: 'Network error: $error',
          );

          debugPrint(
            'Queue ID $id kept locally '
            'because network is unavailable.',
          );

          break;
        } catch (error) {
          await uploadQueueService.updateTemporaryFailure(
            id: id,
            error:
                'Unexpected upload error: '
                '$error',
          );

          debugPrint(
            'Queue ID $id kept locally '
            'after unexpected error: $error',
          );

          break;
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}
