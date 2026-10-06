import 'dart:convert';

enum HelpRequestNotificationEvent { created, acknowledged, resolved }

class HelpRequestNotification {
  const HelpRequestNotification._({
    required this.helpRequestId,
    required this.patientId,
    required this.event,
    required this.status,
    required this.eventId,
    this.patientDisplayName,
  });

  final String helpRequestId;
  final String patientId;
  final HelpRequestNotificationEvent event;
  final String status;
  final String eventId;
  final String? patientDisplayName;

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );

  static HelpRequestNotification? parse(Object? payload, {String? messageId}) {
    if (payload is! Map || payload['type'] != 'HELP_REQUEST') {
      return null;
    }

    final helpRequestId = payload['help_request_id'];
    final patientId = payload['patient_id'];
    final eventValue = payload['event'];
    final status = payload['status'];

    if (helpRequestId is! String ||
        patientId is! String ||
        eventValue is! String ||
        status is! String ||
        !_uuid.hasMatch(helpRequestId) ||
        !_uuid.hasMatch(patientId)) {
      return null;
    }

    final event = switch (eventValue) {
      'CREATED' => HelpRequestNotificationEvent.created,
      'ACKNOWLEDGED' => HelpRequestNotificationEvent.acknowledged,
      'RESOLVED' => HelpRequestNotificationEvent.resolved,
      _ => null,
    };

    final expectedStatus = switch (event) {
      HelpRequestNotificationEvent.created => 'PENDING',
      HelpRequestNotificationEvent.acknowledged => 'ACKNOWLEDGED',
      HelpRequestNotificationEvent.resolved => 'RESOLVED',
      null => null,
    };

    if (event == null || status != expectedStatus) {
      return null;
    }

    final localEventId = payload['_notification_event_id'];
    final displayName = payload['patient_display_name'];

    return HelpRequestNotification._(
      helpRequestId: helpRequestId.toLowerCase(),
      patientId: patientId.toLowerCase(),
      event: event,
      status: status,
      patientDisplayName: displayName is String && displayName.trim().isNotEmpty
          ? displayName.trim()
          : null,
      eventId: messageId != null && messageId.isNotEmpty
          ? 'message:$messageId'
          : localEventId is String && localEventId.isNotEmpty
          ? 'message:$localEventId'
          : 'help-request:${helpRequestId.toLowerCase()}:$eventValue',
    );
  }

  static HelpRequestNotification? fromLocalPayload(String? payload) {
    if (payload == null) return null;

    try {
      return parse(jsonDecode(payload));
    } on FormatException {
      return null;
    }
  }
}

/// Retains notification taps or early foreground arrivals until the active
/// authenticated role subscribes. Repeated FCM delivery is ignored.
class HelpRequestNotificationBus {
  HelpRequestNotificationBus();

  static final instance = HelpRequestNotificationBus();

  final _seen = <String>{};
  final _pending = <HelpRequestNotification>[];
  void Function(HelpRequestNotification)? _listener;

  void Function() subscribe(void Function(HelpRequestNotification) listener) {
    _listener = listener;

    final pending = List<HelpRequestNotification>.of(_pending);
    _pending.clear();

    for (final event in pending) {
      listener(event);
    }

    return () {
      if (identical(_listener, listener)) {
        _listener = null;
        _pending.clear();
      }
    };
  }

  void handle(HelpRequestNotification? event) {
    if (event == null || !_seen.add(event.eventId)) return;

    if (_seen.length > 128) {
      _seen.remove(_seen.first);
    }

    final listener = _listener;
    if (listener != null) {
      listener(event);
      return;
    }

    if (_pending.length == 32) {
      _pending.removeAt(0);
    }
    _pending.add(event);
  }
}
