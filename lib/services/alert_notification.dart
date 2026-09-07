import 'dart:convert';

/// Platform-independent data for a caregiver alert notification tap.
class AlertNotification {
  final String alertId;
  final String eventId;

  const AlertNotification._(this.alertId, this.eventId);

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static AlertNotification? parse(Object? payload, {String? messageId}) {
    if (payload is! Map || payload['type'] != 'ALERT') return null;
    final id = payload['alert_id'];
    if (id is! String || !_uuid.hasMatch(id)) return null;
    final alertId = id.toLowerCase();
    final eventId = messageId != null && messageId.isNotEmpty
        ? messageId
        : payload['_notification_event_id'];
    return AlertNotification._(
      alertId,
      eventId is String && eventId.isNotEmpty
          ? 'message:$eventId'
          : 'alert:$alertId',
    );
  }

  static AlertNotification? fromLocalPayload(String? payload) {
    if (payload == null) return null;
    try {
      return parse(jsonDecode(payload));
    } on FormatException {
      return null;
    }
  }
}

/// Retains startup taps until an authenticated caregiver shell subscribes.
/// Event identity survives unsubscribe so redelivery cannot reopen a route.
class NotificationTapBus {
  NotificationTapBus();
  static final instance = NotificationTapBus();
  final _seen = <String>{};
  final _pending = <AlertNotification>[];
  void Function(AlertNotification)? _onAlert;

  void Function() subscribe(void Function(AlertNotification) onAlert) {
    _onAlert = onAlert;
    final pending = List<AlertNotification>.of(_pending);
    _pending.clear();
    for (final event in pending) {
      onAlert(event);
    }
    return () {
      if (identical(_onAlert, onAlert)) {
        _onAlert = null;
        _pending.clear();
      }
    };
  }

  void handle(AlertNotification? event) {
    if (event == null || !_seen.add(event.eventId)) return;
    // Bound memory while retaining recent notification identities.
    if (_seen.length > 128) _seen.remove(_seen.first);
    final listener = _onAlert;
    if (listener != null) {
      listener(event);
    } else {
      if (_pending.length == 32) _pending.removeAt(0);
      _pending.add(event);
    }
  }
}
