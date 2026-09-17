import 'package:alera/services/patient_nudge_notification.dart';
import 'package:flutter_test/flutter_test.dart';

const nudgeId = '12345678-1234-4234-9234-123456789abc';
const patientId = '87654321-4321-4321-8321-cba987654321';

void main() {
  test('parses the strict NUDGE contract', () {
    final event = PatientNudgeNotification.parse({
      'type': 'NUDGE',
      'nudge_id': nudgeId,
      'patient_id': patientId,
      'nudge_type': 'TAKE_MEDICATION',
    }, messageId: 'message-1');

    expect(event?.nudgeId, nudgeId);
    expect(event?.patientId, patientId);
    expect(event?.type, PatientNudgeType.takeMedication);
    expect(event?.eventId, 'message:message-1');
  });

  test('rejects malformed, alert, and unsupported nudge payloads', () {
    for (final payload in <Object?>[
      null,
      [],
      {},
      {'type': 'ALERT', 'nudge_id': nudgeId},
      {
        'type': 'NUDGE',
        'nudge_id': '../bad',
        'patient_id': patientId,
        'nudge_type': 'DRINK_WATER',
      },
      {
        'type': 'NUDGE',
        'nudge_id': nudgeId,
        'patient_id': patientId,
        'nudge_type': 'CUSTOM_MESSAGE',
      },
    ]) {
      expect(PatientNudgeNotification.parse(payload), isNull);
    }
  });

  test('queues cold-start taps and deduplicates local delivery', () {
    final bus = PatientNudgeTapBus();
    final received = <PatientNudgeNotification>[];
    bus.handle(
      PatientNudgeNotification.parse({
        'type': 'NUDGE',
        'nudge_id': nudgeId,
        'patient_id': patientId,
        'nudge_type': 'DRINK_WATER',
        '_notification_event_id': 'same-message',
      }),
    );
    bus.handle(
      PatientNudgeNotification.fromLocalPayload(
        '{"type":"NUDGE","nudge_id":"$nudgeId",'
        '"patient_id":"$patientId","nudge_type":"DRINK_WATER",'
        '"_notification_event_id":"same-message"}',
      ),
    );
    bus.subscribe(received.add);
    expect(received, hasLength(1));
    expect(received.single.type, PatientNudgeType.drinkWater);
  });
}
