/// Kinds of entries in a reminder occurrence's history. [unknown] is the
/// safe fallback for any type the backend adds later.
enum ReminderEventType {
  created('CREATED'),
  notificationSent('NOTIFICATION_SENT'),
  snoozed('SNOOZED'),
  completed('COMPLETED'),
  completedLate('COMPLETED_LATE'),
  completedOnBehalf('COMPLETED_ON_BEHALF'),
  canceled('CANCELED'),
  markedMissed('MARKED_MISSED'),
  unknown('UNKNOWN');

  const ReminderEventType(this.apiValue);
  final String apiValue;

  static ReminderEventType parse(Object? value) {
    for (final type in values) {
      if (type != unknown && type.apiValue == value) return type;
    }
    return unknown;
  }
}

enum ReminderActorRole {
  caregiver('CAREGIVER'),
  patient('PATIENT'),
  system('SYSTEM'),
  unknown('UNKNOWN');

  const ReminderActorRole(this.apiValue);
  final String apiValue;

  static ReminderActorRole parse(Object? value) {
    for (final role in values) {
      if (role != unknown && role.apiValue == value) return role;
    }
    return unknown;
  }
}

class ReminderEvent {
  const ReminderEvent({
    required this.id,
    required this.occurrenceId,
    required this.type,
    required this.occurredAt,
    required this.actorRole,
    this.rawType,
    this.actorUserId,
    this.actorDisplayName,
    this.note,
    this.metadata = const {},
  });

  final String id;
  final String occurrenceId;
  final ReminderEventType type;

  /// The backend's original type string; only useful for [ReminderEventType.unknown].
  final String? rawType;
  final DateTime occurredAt;
  final String? actorUserId;
  final ReminderActorRole actorRole;
  final String? actorDisplayName;
  final String? note;
  final Map<String, Object?> metadata;

  /// `metadata.snoozed_until` when present and valid.
  DateTime? get snoozedUntil {
    final value = metadata['snoozed_until'];
    return value is String ? DateTime.tryParse(value) : null;
  }

  /// `metadata.audience`, e.g. "PATIENT" or "CAREGIVER".
  String? get audience => _metaString('audience');

  /// `metadata.channel`, e.g. "PUSH".
  String? get channel => _metaString('channel');

  String? _metaString(String key) {
    final value = metadata[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }
}
