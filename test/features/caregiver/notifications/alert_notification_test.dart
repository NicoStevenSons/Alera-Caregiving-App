import 'package:alera/services/alert_notification.dart';
import 'package:flutter_test/flutter_test.dart';

const alertId = '12345678-1234-1234-1234-123456789abc';

void main() {
  test('parses valid ALERT data and preserves event identity', () {
    final event = AlertNotification.parse({
      'type': 'ALERT',
      'alert_id': alertId,
      'patient_id': 'patient',
    }, messageId: 'message-1');
    expect(event?.alertId, alertId);
    expect(event?.eventId, 'message:message-1');
  });

  test('ignores malformed payloads and invalid IDs', () {
    for (final payload in <Object?>[
      null,
      [],
      'invalid',
      {},
      {'type': 'OTHER', 'alert_id': alertId},
      {'type': 'ALERT'},
      {'type': 'ALERT', 'alert_id': 42},
      {'type': 'ALERT', 'alert_id': ''},
      {'type': 'ALERT', 'alert_id': '   '},
      {'type': 'ALERT', 'alert_id': '../alerts'},
      {'type': 'ALERT', 'alert_id': 'not-a-uuid'},
    ]) {
      expect(AlertNotification.parse(payload), isNull);
    }
    expect(AlertNotification.fromLocalPayload('{broken'), isNull);
    expect(AlertNotification.fromLocalPayload('[]'), isNull);
    expect(AlertNotification.fromLocalPayload(null), isNull);
  });

  test(
    'normalizes UUID case and uses local identity for an empty message ID',
    () {
      final event = AlertNotification.parse({
        'type': 'ALERT',
        'alert_id': alertId.toUpperCase(),
        '_notification_event_id': 'local-message',
      }, messageId: '');
      expect(event?.alertId, alertId);
      expect(event?.eventId, 'message:local-message');
    },
  );

  test('queues cold-start tap and deduplicates remote/local delivery', () {
    final bus = NotificationTapBus();
    final events = <AlertNotification>[];
    final remote = AlertNotification.parse({
      'type': 'ALERT',
      'alert_id': alertId,
    }, messageId: 'message-1');
    final local = AlertNotification.fromLocalPayload(
      '{"type":"ALERT","alert_id":"$alertId",'
      '"_notification_event_id":"message-1"}',
    );
    bus.handle(remote);
    bus.handle(local);
    final unsubscribe = bus.subscribe(events.add);
    expect(events.map((e) => e.alertId), [alertId]);
    bus.handle(remote);
    expect(events, hasLength(1));
    unsubscribe();
    bus.handle(remote);
    bus.subscribe(events.add);
    expect(events, hasLength(1));
  });

  test('missing message ID deduplicates across remote and local taps', () {
    final bus = NotificationTapBus();
    final events = <AlertNotification>[];
    bus.subscribe(events.add);
    bus.handle(AlertNotification.parse({'type': 'ALERT', 'alert_id': alertId}));
    bus.handle(
      AlertNotification.fromLocalPayload(
        '{"type":"ALERT","alert_id":"$alertId","_notification_event_id":null}',
      ),
    );
    expect(events, hasLength(1));
  });

  test('different messages for the same alert remain distinct', () {
    final bus = NotificationTapBus();
    final events = <AlertNotification>[];
    final unsubscribe = bus.subscribe(events.add);
    for (final id in ['one', 'two']) {
      bus.handle(
        AlertNotification.parse({
          'type': 'ALERT',
          'alert_id': alertId,
        }, messageId: id),
      );
    }
    expect(events, hasLength(2));
    unsubscribe();
    bus.handle(
      AlertNotification.parse({
        'type': 'ALERT',
        'alert_id': alertId,
      }, messageId: 'three'),
    );
    expect(events, hasLength(2));
  });
}
