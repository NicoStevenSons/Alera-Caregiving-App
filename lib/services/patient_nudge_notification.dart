import 'dart:convert';

enum PatientNudgeType {
  drinkWater('DRINK_WATER', 'Drink water'),
  takeMedication('TAKE_MEDICATION', 'Take medication'),
  checkBloodPressure('CHECK_BLOOD_PRESSURE', 'Check blood pressure');

  final String apiValue;
  final String label;

  const PatientNudgeType(this.apiValue, this.label);

  static PatientNudgeType? fromApiValue(Object? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}

class PatientNudgeNotification {
  final String nudgeId;
  final String patientId;
  final PatientNudgeType type;
  final String eventId;

  const PatientNudgeNotification._({
    required this.nudgeId,
    required this.patientId,
    required this.type,
    required this.eventId,
  });

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static PatientNudgeNotification? parse(Object? payload, {String? messageId}) {
    if (payload is! Map || payload['type'] != 'NUDGE') return null;
    final nudgeId = payload['nudge_id'];
    final patientId = payload['patient_id'];
    final type = PatientNudgeType.fromApiValue(payload['nudge_type']);
    if (nudgeId is! String ||
        patientId is! String ||
        !_uuid.hasMatch(nudgeId) ||
        !_uuid.hasMatch(patientId) ||
        type == null) {
      return null;
    }
    final localEventId = payload['_notification_event_id'];
    return PatientNudgeNotification._(
      nudgeId: nudgeId.toLowerCase(),
      patientId: patientId.toLowerCase(),
      type: type,
      eventId: messageId != null && messageId.isNotEmpty
          ? 'message:$messageId'
          : localEventId is String && localEventId.isNotEmpty
          ? 'message:$localEventId'
          : 'nudge:${nudgeId.toLowerCase()}',
    );
  }

  static PatientNudgeNotification? fromLocalPayload(String? payload) {
    if (payload == null) return null;
    try {
      return parse(jsonDecode(payload));
    } on FormatException {
      return null;
    }
  }
}

class PatientNudgeTapBus {
  PatientNudgeTapBus();
  static final instance = PatientNudgeTapBus();
  final _seen = <String>{};
  final _pending = <PatientNudgeNotification>[];
  void Function(PatientNudgeNotification)? _listener;

  void Function() subscribe(void Function(PatientNudgeNotification) listener) {
    _listener = listener;
    final pending = List<PatientNudgeNotification>.of(_pending);
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

  void handle(PatientNudgeNotification? event) {
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
