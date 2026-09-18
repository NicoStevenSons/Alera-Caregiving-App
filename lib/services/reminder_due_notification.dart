import 'dart:convert';

enum ReminderNotificationAction { open, complete, snooze }

class ReminderDueNotification {
  const ReminderDueNotification._({
    required this.occurrenceId,
    required this.templateId,
    required this.patientId,
    required this.eventId,
    this.action = ReminderNotificationAction.open,
    this.instructions,
  });

  final String occurrenceId;
  final String templateId;
  final String patientId;
  final String? instructions;
  final String eventId;
  final ReminderNotificationAction action;

  ReminderDueNotification withAction(ReminderNotificationAction value) {
    return ReminderDueNotification._(
      occurrenceId: occurrenceId,
      templateId: templateId,
      patientId: patientId,
      eventId: '$eventId:${value.name}',
      instructions: instructions,
      action: value,
    );
  }

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static ReminderDueNotification? parse(Object? payload, {String? messageId}) {
    if (payload is! Map || payload['type'] != 'REMINDER_DUE') return null;
    final occurrenceId = payload['occurrence_id'];
    final templateId = payload['template_id'];
    final patientId = payload['patient_id'];
    if (occurrenceId is! String ||
        templateId is! String ||
        patientId is! String ||
        !_uuid.hasMatch(occurrenceId) ||
        !_uuid.hasMatch(templateId) ||
        !_uuid.hasMatch(patientId)) {
      return null;
    }
    final localEventId = payload['_notification_event_id'];
    final instructions = payload['instructions'];
    return ReminderDueNotification._(
      occurrenceId: occurrenceId.toLowerCase(),
      templateId: templateId.toLowerCase(),
      patientId: patientId.toLowerCase(),
      instructions: instructions is String && instructions.isNotEmpty
          ? instructions
          : null,
      eventId: messageId != null && messageId.isNotEmpty
          ? 'message:$messageId'
          : localEventId is String && localEventId.isNotEmpty
          ? 'message:$localEventId'
          : 'reminder:${occurrenceId.toLowerCase()}',
    );
  }

  static ReminderDueNotification? fromLocalPayload(String? payload) {
    if (payload == null) return null;
    try {
      return parse(jsonDecode(payload));
    } on FormatException {
      return null;
    }
  }
}

class ReminderDueTapBus {
  ReminderDueTapBus();
  static final instance = ReminderDueTapBus();
  final _seen = <String>{};
  final _pending = <ReminderDueNotification>[];
  void Function(ReminderDueNotification)? _listener;

  void Function() subscribe(void Function(ReminderDueNotification) listener) {
    _listener = listener;
    final pending = List<ReminderDueNotification>.of(_pending);
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

  void handle(ReminderDueNotification? event) {
    if (event == null || !_seen.add(event.eventId)) return;
    if (_seen.length > 128) _seen.remove(_seen.first);
    final listener = _listener;
    if (listener != null) {
      listener(event);
    } else {
      if (_pending.length == 32) _pending.removeAt(0);
      _pending.add(event);
    }
  }
}
