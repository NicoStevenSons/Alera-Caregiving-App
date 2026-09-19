import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../caregiver/data/auth/caregiver_session_controller.dart';

class ActivityDataApiService {
  final String baseUrl;
  final String patientId;

  final CaregiverSession _session;
  final http.Client _client;

  final Duration timeout;

  ActivityDataApiService({
    required this.baseUrl,
    required this.patientId,
    CaregiverSession? session,
    http.Client? client,
    this.timeout = const Duration(
      seconds: 15,
    ),
  }) : _session =
           session ??
           CaregiverSessionController.instance,
       _client = client ?? http.Client();

  Future<bool> sendActivityData(
    Map<String, dynamic> payload,
  ) async {
    final String? token =
        _session.accessToken;

    if (token == null || token.isEmpty) {
      debugPrint(
        'Activity data not sent: '
        'no patient session token.',
      );

      return false;
    }

    try {
      final http.Response response =
          await _client
              .post(
                Uri.parse(
                  '$baseUrl/api/v1/activity-data',
                ),
                headers: {
                  'authorization':
                      'Bearer $token',
                  'content-type':
                      'application/json',
                },
                body: jsonEncode(payload),
              )
              .timeout(timeout);

      debugPrint(
        'Activity data response: '
        '${response.statusCode} '
        '${response.body}',
      );

      if (response.statusCode == 401) {
        await _session
            .clearInvalidSession();

        return false;
      }

      if (
        response.statusCode < 200 ||
        response.statusCode >= 300
      ) {
        return false;
      }

      return true;
    } on TimeoutException {
      debugPrint(
        'Activity data upload timed out.',
      );

      return false;
    } on http.ClientException catch (error) {
      debugPrint(
        'Activity data network error: '
        '$error',
      );

      return false;
    } catch (error) {
      debugPrint(
        'Activity data upload failed: '
        '$error',
      );

      return false;
    }
  }
}