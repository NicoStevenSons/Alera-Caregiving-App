import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:alera/features/caregiver/data/api/caregiver_insight_api_data_source.dart';
import 'package:alera/features/caregiver/data/api/dto/caregiver_insight_dto.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';

class _FakeSession implements CaregiverSession {
  @override
  String? accessToken = 'test-token';

  @override
  String? householdCode;

  bool cleared = false;

  @override
  Future<void> clearInvalidSession() async {
    cleared = true;
    accessToken = null;
  }
}

Map<String, Object?> _responseJson() => {
  'patient_id': '00000000-0000-4000-8000-000000000001',
  'range': '7d',
  'from_at': '2026-10-14T00:00:00Z',
  'to_at': '2026-10-21T00:00:00Z',
  'source': 'ai_ranked',
  'summary': 'Review the latest readings.',
  'items': [
    {
      'insight_id': 'CRITICAL_ALERTS_RECORDED',
      'priority': 'critical',
      'title': 'Critical alerts were recorded',
      'message': 'One critical alert was recorded during this period.',
      'evidence_keys': ['alerts.critical'],
    },
  ],
  'disclaimer': 'Not a diagnosis.',
};

void main() {
  test(
    'fetches authenticated patient insights and parses the response',
    () async {
      final session = _FakeSession();
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          endsWith(
            '/api/v1/patients/00000000-0000-4000-8000-000000000001/'
            'caregiver-insights',
          ),
        );
        expect(request.headers['authorization'], 'Bearer test-token');
        return http.Response(jsonEncode(_responseJson()), 200);
      });
      final source = CaregiverInsightApiDataSource(
        client: client,
        session: session,
      );

      final result = await source.fetchInsights(
        '00000000-0000-4000-8000-000000000001',
      );

      expect(result.source, CaregiverInsightSource.aiRanked);
      expect(result.items, hasLength(1));
      expect(result.items.single.priority, CaregiverInsightPriority.critical);
      expect(result.items.single.evidenceKeys, ['alerts.critical']);
      expect(session.cleared, isFalse);
      client.close();
    },
  );

  test('clears an invalid caregiver session on HTTP 401', () async {
    final session = _FakeSession();
    final client = MockClient(
      (_) async => http.Response('{"detail":"Not authenticated"}', 401),
    );
    final source = CaregiverInsightApiDataSource(
      client: client,
      session: session,
    );

    await expectLater(
      source.fetchInsights('patient-id'),
      throwsA(
        isA<CaregiverInsightApiFailure>().having(
          (failure) => failure.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(session.cleared, isTrue);
    client.close();
  });
}
