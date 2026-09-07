import 'dart:convert';
import 'dart:async';

import 'package:alera/features/caregiver/data/api/caregiver_alert_api_data_source.dart';
import 'package:alera/features/caregiver/domain/models/caregiver_alert.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'detail requests exact alert with caregiver bearer and maps response',
    () async {
      final source = CaregiverAlertApiDataSource(
        session: _FakeSession('caregiver-token'),
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/alerts/exact-alert');
          expect(request.url.query, isEmpty);
          expect(request.headers['authorization'], 'Bearer caregiver-token');
          return http.Response(
            jsonEncode(
              _alertJson(
                alertId: 'exact-alert',
                conditionKey: 'HR_HIGH',
                metricType: 'HEART_RATE',
                severity: 'WARNING',
                reading: 120,
                unit: 'BPM',
                threshold: 100,
              ),
            ),
            200,
          );
        }),
      );
      expect((await source.fetchAlert('exact-alert')).id, 'exact-alert');
    },
  );

  for (final status in [401, 403, 404, 500]) {
    test('detail HTTP $status preserves auth and error behavior', () async {
      final session = _FakeSession('token');
      final source = CaregiverAlertApiDataSource(
        session: session,
        client: MockClient((_) async => http.Response('{}', status)),
      );
      await expectLater(
        source.fetchAlert('alert'),
        throwsA(isA<CaregiverAlertsFailure>()),
      );
      expect(session.cleared, status == 401);
    });
  }

  test('late detail 401 does not clear a replacement session', () async {
    final session = _FakeSession('old');
    final response = Completer<http.Response>();
    final source = CaregiverAlertApiDataSource(
      session: session,
      client: MockClient((_) => response.future),
    );
    final request = source.fetchAlert('alert');
    session.accessToken = 'new';
    response.complete(http.Response('{}', 401));
    await expectLater(request, throwsA(isA<CaregiverAlertsAuthFailure>()));
    expect(session.cleared, isFalse);
    expect(session.accessToken, 'new');
  });

  test('detail rejects malformed JSON', () async {
    final source = CaregiverAlertApiDataSource(
      session: _FakeSession('token'),
      client: MockClient((_) async => http.Response('broken', 200)),
    );
    await expectLater(
      source.fetchAlert('alert'),
      throwsA(isA<CaregiverAlertsParseFailure>()),
    );
  });

  test('detail cannot substitute a different alert response', () async {
    final source = CaregiverAlertApiDataSource(
      session: _FakeSession('token'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(
            _alertJson(
              alertId: 'different-alert',
              conditionKey: 'HR_HIGH',
              metricType: 'HEART_RATE',
              severity: 'WARNING',
              reading: 120,
              unit: 'BPM',
              threshold: 100,
            ),
          ),
          200,
        ),
      ),
    );
    await expectLater(
      source.fetchAlert('requested-alert'),
      throwsA(isA<CaregiverAlertsParseFailure>()),
    );
  });

  test(
    'late successful detail is discarded after session replacement',
    () async {
      final session = _FakeSession('old');
      final response = Completer<http.Response>();
      final source = CaregiverAlertApiDataSource(
        session: session,
        client: MockClient((_) => response.future),
      );
      final request = source.fetchAlert('alert');
      session.accessToken = 'new';
      response.complete(http.Response('{}', 200));
      await expectLater(request, throwsA(isA<CaregiverAlertsAuthFailure>()));
      expect(session.accessToken, 'new');
      expect(session.cleared, isFalse);
    },
  );

  test('maps heart-rate API JSON into the shared alert-card model', () async {
    final CaregiverAlertApiDataSource source = _sourceFor([
      _alertJson(
        alertId: 'hr-alert',
        conditionKey: 'HR_HIGH',
        metricType: 'HEART_RATE',
        severity: 'WARNING',
        reading: '121.00',
        unit: 'BPM',
        threshold: 100,
      ),
    ]);

    final CaregiverAlert alert = (await source.fetchAlerts()).single;

    expect(alert.id, 'hr-alert');
    expect(alert.careRecipientId, 'patient-1');
    expect(alert.patientDisplayName, 'Nana');
    expect(alert.metric, CaregiverAlertMetric.heartRate);
    expect(alert.severity, CaregiverAlertSeverity.warning);
    expect(alert.status, CaregiverAlertStatus.active);
    expect(alert.reading, 121);
    expect(alert.threshold, 100);
    expect(alert.unit, 'BPM');
    expect(alert.triggerDuration, const Duration(minutes: 5));
  });

  test('maps SpO2 API JSON and terminal lifecycle status', () async {
    final CaregiverAlertApiDataSource source = _sourceFor([
      _alertJson(
        alertId: 'spo2-alert',
        conditionKey: 'SPO2_LOW',
        metricType: 'SPO2',
        severity: 'CRITICAL',
        status: 'FALSE_ALARM',
        reading: 88.5,
        unit: '%',
        threshold: '92.00',
      ),
    ]);

    final CaregiverAlert alert = (await source.fetchAlerts()).single;

    expect(alert.metric, CaregiverAlertMetric.spo2);
    expect(alert.severity, CaregiverAlertSeverity.critical);
    expect(alert.status, CaregiverAlertStatus.falseAlarm);
    expect(alert.reading, 88.5);
    expect(alert.threshold, 92);
    expect(alert.unit, '%');
  });

  test('missing optional display values use safe defaults', () async {
    final Map<String, dynamic> json =
        _alertJson(
          alertId: 'minimal-alert',
          conditionKey: 'HR_LOW',
          metricType: 'HEART_RATE',
          severity: 'WARNING',
          reading: null,
          unit: null,
          threshold: null,
        )..addAll({
          'patient_display_name': null,
          'title': null,
          'evaluation_reason': null,
          'confirmed_at': 'not-a-date',
        });

    final CaregiverAlert alert = (await _sourceFor([
      json,
    ]).fetchAlerts()).single;

    expect(alert.patientDisplayName, isNull);
    expect(alert.title, 'Health alert');
    expect(alert.description, '');
    expect(alert.reading, 0);
    expect(alert.threshold, isNull);
    expect(alert.unit, '');
    expect(alert.triggerDuration, isNull);
  });

  test('throws a typed failure for a non-success response', () async {
    final CaregiverAlertApiDataSource source = CaregiverAlertApiDataSource(
      client: MockClient((_) async => http.Response('unavailable', 503)),
      session: _FakeSession('test-token'),
    );

    expect(source.fetchAlerts(), throwsA(isA<CaregiverAlertsHttpFailure>()));
  });

  test('401 clears the caregiver session', () async {
    final _FakeSession session = _FakeSession('expired-token');
    final CaregiverAlertApiDataSource source = CaregiverAlertApiDataSource(
      client: MockClient((http.Request request) async {
        expect(request.headers['authorization'], 'Bearer expired-token');
        return http.Response('unauthorized', 401);
      }),
      session: session,
    );

    await expectLater(
      source.fetchAlerts(),
      throwsA(isA<CaregiverAlertsAuthFailure>()),
    );
    expect(session.cleared, isTrue);
    expect(session.accessToken, isNull);
  });

  final actionCases =
      <
        ({
          String path,
          Map<String, Object> body,
          Future<CaregiverAlert> Function(CaregiverAlertApiDataSource) invoke,
        })
      >[
        (
          path: '/api/v1/alerts/alert-1/acknowledge',
          body: {'note': 'Seen'},
          invoke: (source) => source.acknowledge('alert-1', note: ' Seen '),
        ),
        (
          path: '/api/v1/alerts/alert-1/resolve',
          body: <String, Object>{},
          invoke: (source) => source.resolve('alert-1'),
        ),
        (
          path: '/api/v1/alerts/alert-1/false-alarm',
          body: {'reason': 'Sensor moved'},
          invoke: (source) =>
              source.markFalseAlarm('alert-1', ' Sensor moved '),
        ),
        (
          path: '/api/v1/alerts/alert-1/notes',
          body: {'note': 'Called patient'},
          invoke: (source) => source.addNote('alert-1', ' Called patient '),
        ),
        (
          path: '/api/v1/alerts/alert-1/interventions',
          body: {
            'intervention_type': 'PATIENT_CHECK',
            'note': 'Patient responded',
          },
          invoke: (source) => source.logIntervention(
            'alert-1',
            CaregiverInterventionType.patientCheck,
            ' Patient responded ',
          ),
        ),
      ];

  for (final actionCase in actionCases) {
    test('action POST ${actionCase.path} sends bearer and body', () async {
      final source = CaregiverAlertApiDataSource(
        session: _FakeSession('caregiver-token'),
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, actionCase.path);
          expect(request.headers['authorization'], 'Bearer caregiver-token');
          expect(jsonDecode(request.body), actionCase.body);
          return http.Response(
            jsonEncode({
              'alert': _alertJson(
                alertId: 'alert-1',
                conditionKey: 'HR_HIGH',
                metricType: 'HEART_RATE',
                severity: 'WARNING',
                status: 'ACKNOWLEDGED',
                reading: 120,
                unit: 'BPM',
                threshold: 100,
              ),
              'action': null,
              'idempotent': true,
            }),
            200,
          );
        }),
      );
      final updated = await actionCase.invoke(source);
      expect(updated.id, 'alert-1');
      expect(updated.status, CaregiverAlertStatus.acknowledged);
    });
  }

  test('401 during an action clears the caregiver session', () async {
    final session = _FakeSession('expired');
    final source = CaregiverAlertApiDataSource(
      session: session,
      client: MockClient((_) async => http.Response('', 401)),
    );
    await expectLater(
      source.resolve('alert-1'),
      throwsA(isA<CaregiverAlertsAuthFailure>()),
    );
    expect(session.cleared, isTrue);
    expect(session.accessToken, isNull);
  });
}

CaregiverAlertApiDataSource _sourceFor(List<Map<String, dynamic>> items) {
  final _FakeSession session = _FakeSession('test-token');
  return CaregiverAlertApiDataSource(
    client: MockClient((http.Request request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/alerts');
      expect(request.url.queryParameters['limit'], '100');
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'items': items,
            'total': items.length,
            'limit': 100,
            'offset': 0,
          }),
        ),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    }),
    session: session,
  );
}

class _FakeSession implements CaregiverSession {
  @override
  String? accessToken;
  @override
  String? get householdCode => 'TEST-HOUSEHOLD';
  bool cleared = false;

  _FakeSession(this.accessToken);

  @override
  Future<void> clearInvalidSession() async {
    accessToken = null;
    cleared = true;
  }
}

Map<String, dynamic> _alertJson({
  required String alertId,
  required String conditionKey,
  required String metricType,
  required String severity,
  String status = 'ACTIVE',
  required Object? reading,
  required String? unit,
  required Object? threshold,
}) {
  return {
    'alert_id': alertId,
    'patient_id': 'patient-1',
    'condition_key': conditionKey,
    'severity': severity,
    'status': status,
    'detected_at': '2026-09-04T10:00:00Z',
    'confirmed_at': '2026-09-04T10:05:00Z',
    'resolved_at': null,
    'created_at': '2026-09-04T10:05:00Z',
    'updated_at': '2026-09-04T10:05:00Z',
    'patient_display_name': 'Nana',
    'metric_type': metricType,
    'title': conditionKey == 'SPO2_LOW' ? 'Low SpO₂' : 'High Heart Rate',
    'reading_value': reading,
    'reading_unit': unit,
    'threshold_value': threshold,
    'threshold_unit': unit,
    'evaluation_reason': 'Threshold exceeded.',
  };
}
