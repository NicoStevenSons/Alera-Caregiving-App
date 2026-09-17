import 'dart:convert';
import 'dart:math';

import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:alera/features/reminders/data/reminder_api_data_source.dart';
import 'package:alera/features/reminders/domain/reminder_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parses paginated occurrences and repeated status filters', () async {
    late http.Request captured;
    final source = ReminderApiDataSource(
      session: _Session('token'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'items': [_occurrenceJson()],
            'total': 1,
            'limit': 100,
            'offset': 0,
          }),
          200,
        );
      }),
    );

    final page = await source.fetchOccurrences(
      patientId: 'patient-id',
      statuses: const [
        ReminderOccurrenceStatus.due,
        ReminderOccurrenceStatus.snoozed,
      ],
    );

    expect(captured.headers['authorization'], 'Bearer token');
    expect(captured.url.path, '/api/v1/reminders');
    expect(captured.url.queryParametersAll['status'], ['DUE', 'SNOOZED']);
    expect(page.items.single.status, ReminderOccurrenceStatus.due);
    expect(page.items.single.scheduledAt.isUtc, isTrue);
  });

  test(
    'complete sends UUID idempotency key and parses updated reminder',
    () async {
      late http.Request captured;
      final source = ReminderApiDataSource(
        session: _Session('token'),
        random: Random(42),
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'reminder': _occurrenceJson(status: 'COMPLETED'),
              'action': {},
              'idempotent': false,
            }),
            200,
          );
        }),
      );

      final result = await source.complete('occurrence-id', note: ' Taken ');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(captured.url.path, '/api/v1/reminders/occurrence-id/complete');
      expect(body['note'], 'Taken');
      expect(
        body['client_action_id'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(result.reminder.status, ReminderOccurrenceStatus.completed);
    },
  );

  test('401 clears only the captured invalid session', () async {
    final session = _Session('expired');
    final source = ReminderApiDataSource(
      session: session,
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    await expectLater(
      source.fetchOccurrences(),
      throwsA(
        isA<ReminderApiFailure>().having((e) => e.statusCode, 'status', 401),
      ),
    );
    expect(session.cleared, isTrue);
  });

  test('rejects unknown enums instead of silently guessing', () async {
    final source = ReminderApiDataSource(
      session: _Session('token'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'items': [_occurrenceJson(status: 'SURPRISE')],
            'total': 1,
            'limit': 100,
            'offset': 0,
          }),
          200,
        ),
      ),
    );
    await expectLater(
      source.fetchOccurrences(),
      throwsA(isA<FormatException>()),
    );
  });
}

Map<String, dynamic> _occurrenceJson({String status = 'DUE'}) => {
  'reminder_occurrence_id': 'occurrence-id',
  'reminder_template_id': 'template-id',
  'patient_id': 'patient-id',
  'title': 'Evening medication',
  'instructions': 'Take one tablet',
  'category': 'MEDICATION',
  'priority': 'HIGH',
  'scheduled_at': '2026-09-17T12:00:00Z',
  'due_at': '2026-09-17T12:15:00Z',
  'status': status,
  'snooze_allowed': true,
  'default_snooze_minutes': 10,
  'missed_after_minutes': 30,
};

class _Session implements CaregiverSession {
  _Session(this.accessToken);
  @override
  String? accessToken;
  bool cleared = false;
  @override
  String? get householdCode => null;
  @override
  Future<void> clearInvalidSession() async {
    cleared = true;
    accessToken = null;
  }
}
