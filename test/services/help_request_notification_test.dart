import 'dart:convert';

import 'package:alera/services/help_request_notification.dart';
import 'package:flutter_test/flutter_test.dart';

const _requestId = '10000000-0000-4000-8000-000000000001';
const _patientId = '20000000-0000-4000-8000-000000000002';

Map<String, Object> _payload({
  String event = 'CREATED',
  String status = 'PENDING',
}) {
  return {
    'type': 'HELP_REQUEST',
    'event': event,
    'help_request_id': _requestId,
    'patient_id': _patientId,
    'status': status,
    'patient_display_name': ' Nana ',
  };
}

void main() {
  test('parses the strict HELP_REQUEST contract', () {
    final event = HelpRequestNotification.parse(
      _payload(),
      messageId: 'message-id',
    );

    expect(event, isNotNull);
    expect(event!.helpRequestId, _requestId);
    expect(event.patientId, _patientId);
    expect(event.event, HelpRequestNotificationEvent.created);
    expect(event.status, 'PENDING');
    expect(event.patientDisplayName, 'Nana');
    expect(event.eventId, 'message:message-id');
  });

  test('parses acknowledged and resolved lifecycle events', () {
    final acknowledged = HelpRequestNotification.parse(
      _payload(event: 'ACKNOWLEDGED', status: 'ACKNOWLEDGED'),
    );
    final resolved = HelpRequestNotification.parse(
      _payload(event: 'RESOLVED', status: 'RESOLVED'),
    );

    expect(acknowledged?.event, HelpRequestNotificationEvent.acknowledged);
    expect(resolved?.event, HelpRequestNotificationEvent.resolved);
  });

  test('rejects malformed and mismatched payloads', () {
    expect(
      HelpRequestNotification.parse(
        _payload(event: 'CREATED', status: 'RESOLVED'),
      ),
      isNull,
    );
    expect(
      HelpRequestNotification.parse({
        ..._payload(),
        'help_request_id': '../request',
      }),
      isNull,
    );
    expect(
      HelpRequestNotification.parse({..._payload(), 'type': 'ALERT'}),
      isNull,
    );
  });

  test('parses local notification JSON payload', () {
    final event = HelpRequestNotification.fromLocalPayload(
      jsonEncode({
        ..._payload(event: 'RESOLVED', status: 'RESOLVED'),
        '_notification_event_id': 'local-message',
      }),
    );

    expect(event?.event, HelpRequestNotificationEvent.resolved);
    expect(event?.eventId, 'message:local-message');
    expect(HelpRequestNotification.fromLocalPayload('{broken'), isNull);
  });

  test('bus retains an early event and deduplicates delivery', () {
    final bus = HelpRequestNotificationBus();
    final event = HelpRequestNotification.parse(
      _payload(),
      messageId: 'same-message',
    );
    final received = <HelpRequestNotification>[];

    bus.handle(event);
    final unsubscribe = bus.subscribe(received.add);
    bus.handle(event);

    expect(received, hasLength(1));
    expect(received.single.eventId, 'message:same-message');

    unsubscribe();
  });
}
