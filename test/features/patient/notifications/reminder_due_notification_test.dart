import 'package:alera/services/reminder_due_notification.dart';
import 'package:flutter_test/flutter_test.dart';

const occurrenceId = '12345678-1234-4234-9234-123456789abc';
const templateId = '22345678-1234-4234-9234-123456789abc';
const patientId = '32345678-1234-4234-9234-123456789abc';

void main() {
  test('parses the strict REMINDER_DUE contract', () {
    final event = ReminderDueNotification.parse({
      'type': 'REMINDER_DUE',
      'occurrence_id': occurrenceId,
      'template_id': templateId,
      'patient_id': patientId,
      'instructions': 'Take one tablet',
    }, messageId: 'message-1');

    expect(event?.occurrenceId, occurrenceId);
    expect(event?.templateId, templateId);
    expect(event?.patientId, patientId);
    expect(event?.instructions, 'Take one tablet');
    expect(event?.eventId, 'message:message-1');
  });

  test('rejects malformed and unrelated payloads', () {
    for (final payload in <Object?>[
      null,
      [],
      {},
      {'type': 'NUDGE', 'occurrence_id': occurrenceId},
      {
        'type': 'REMINDER_DUE',
        'occurrence_id': '../bad',
        'template_id': templateId,
        'patient_id': patientId,
      },
    ]) {
      expect(ReminderDueNotification.parse(payload), isNull);
    }
  });
}
