import '../domain/reminder_event.dart';
import '../domain/reminder_models.dart';

String? _optionalText(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class ReminderEventDto {
  const ReminderEventDto(this.value);
  final ReminderEvent value;

  /// Required: `event_id`, `reminder_occurrence_id`, `occurred_at`.
  /// Everything else is optional and an unrecognised `event_type` or
  /// `actor_role` becomes an `unknown` value instead of throwing.
  factory ReminderEventDto.fromJson(Map<String, dynamic> json) {
    final id = _optionalText(json['event_id']);
    final occurrenceId = _optionalText(json['reminder_occurrence_id']);
    final occurredText = _optionalText(json['occurred_at']);
    final occurredAt = occurredText == null
        ? null
        : DateTime.tryParse(occurredText);
    if (id == null || occurrenceId == null || occurredAt == null) {
      throw const FormatException('Reminder event is missing required fields.');
    }
    final type = ReminderEventType.parse(json['event_type']);
    final metadata = json['metadata'];
    return ReminderEventDto(
      ReminderEvent(
        id: id,
        occurrenceId: occurrenceId,
        type: type,
        rawType: type == ReminderEventType.unknown
            ? _optionalText(json['event_type'])
            : null,
        occurredAt: occurredAt.toUtc(),
        actorUserId: _optionalText(json['actor_user_id']),
        actorRole: ReminderActorRole.parse(json['actor_role']),
        actorDisplayName: _optionalText(json['actor_display_name']),
        note: _optionalText(json['note']),
        metadata: metadata is Map
            ? {
                for (final entry in metadata.entries)
                  if (entry.key is String) entry.key as String: entry.value,
              }
            : const {},
      ),
    );
  }
}

/// Parses `{items, total, limit, offset}` keeping the backend's oldest-first
/// order.
ReminderPage<ReminderEvent> parseReminderEventPage(Object? decoded) {
  if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
    throw const FormatException('Reminder events must contain an items list.');
  }
  final items = <ReminderEvent>[
    for (final item in decoded['items'] as List)
      if (item is Map<String, dynamic>) ReminderEventDto.fromJson(item).value,
  ];
  int number(String key, int fallback) {
    final value = decoded[key];
    return value is int ? value : fallback;
  }

  return ReminderPage<ReminderEvent>(
    items: items,
    total: number('total', items.length),
    limit: number('limit', items.length),
    offset: number('offset', 0),
  );
}
