import 'dart:async';

import 'package:alera/features/reminders/data/reminder_api_data_source.dart';
import 'package:alera/features/reminders/domain/reminder_event.dart';
import 'package:alera/features/reminders/domain/reminder_models.dart';

Map<String, dynamic> eventJson({
  String id = 'e1',
  String type = 'CREATED',
  String occurredAt = '2026-10-07T12:00:00Z',
  String? actorUserId = 'u1',
  String? actorRole = 'CAREGIVER',
  String? actorName = 'Maria Santos',
  String? note,
  Object? metadata = const <String, Object?>{},
}) => {
  'event_id': id,
  'reminder_occurrence_id': 'occ-1',
  'event_type': type,
  'occurred_at': occurredAt,
  'actor_user_id': actorUserId,
  'actor_role': actorRole,
  'actor_display_name': actorName,
  'note': note,
  'metadata': metadata,
};

ReminderEvent event({
  String id = 'e1',
  ReminderEventType type = ReminderEventType.created,
  String? rawType,
  DateTime? occurredAt,
  ReminderActorRole role = ReminderActorRole.caregiver,
  String? actorName = 'Maria Santos',
  String? note,
  Map<String, Object?> metadata = const {},
}) => ReminderEvent(
  id: id,
  occurrenceId: 'occ-1',
  type: type,
  rawType: rawType,
  occurredAt: occurredAt ?? DateTime.utc(2026, 10, 7, 12),
  actorRole: role,
  actorDisplayName: actorName,
  note: note,
  metadata: metadata,
);

/// Serves [events] in pages, like the backend (oldest first). Failures queued
/// in [failures] are thrown by the next calls, one per call.
class FakeEventsSource implements ReminderEventsDataSource {
  FakeEventsSource(this.events, {int? total}) : total = total ?? events.length;

  final List<ReminderEvent> events;
  int total;
  final List<Object> failures = [];
  final List<int> offsets = [];
  Completer<void>? gate;

  @override
  Future<ReminderPage<ReminderEvent>> fetchEvents(
    String occurrenceId, {
    int limit = 50,
    int offset = 0,
  }) async {
    offsets.add(offset);
    await gate?.future;
    if (failures.isNotEmpty) throw failures.removeAt(0);
    final end = (offset + limit).clamp(0, events.length);
    final start = offset.clamp(0, events.length);
    return ReminderPage(
      items: events.sublist(start, end),
      total: total,
      limit: limit,
      offset: offset,
    );
  }
}

ReminderOccurrence occurrence({
  String id = 'occ-1',
  String title = 'Morning pills',
  ReminderOccurrenceStatus status = ReminderOccurrenceStatus.due,
  String? instructions = 'Take with water',
  bool snoozeAllowed = true,
  DateTime? scheduledAt,
}) => ReminderOccurrence(
  id: id,
  templateId: 'tpl-1',
  patientId: 'p1',
  title: title,
  instructions: instructions,
  category: ReminderCategory.medication,
  priority: ReminderPriority.normal,
  scheduledAt: scheduledAt ?? DateTime(2026, 9, 22, 8, 30),
  dueAt: (scheduledAt ?? DateTime(2026, 9, 22, 8, 30)).add(
    const Duration(minutes: 15),
  ),
  status: status,
  snoozeAllowed: snoozeAllowed,
  defaultSnoozeMinutes: 10,
  missedAfterMinutes: 30,
);
