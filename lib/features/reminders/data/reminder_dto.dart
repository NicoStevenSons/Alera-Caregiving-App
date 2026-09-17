import '../domain/reminder_models.dart';

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw FormatException('$key must be a non-empty string.');
  return value;
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

bool _boolean(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('$key must be a boolean.');
  return value;
}

DateTime _dateTime(Map<String, dynamic> json, String key) {
  final parsed = DateTime.tryParse(_string(json, key));
  if (parsed == null || !parsed.isUtc) throw FormatException('$key must be an ISO-8601 UTC datetime.');
  return parsed;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value != null && value is! String) throw FormatException('$key must be a string or null.');
  return value as String?;
}

class ReminderOccurrenceDto {
  const ReminderOccurrenceDto(this.value);
  final ReminderOccurrence value;

  factory ReminderOccurrenceDto.fromJson(Map<String, dynamic> json) {
    return ReminderOccurrenceDto(ReminderOccurrence(
      id: _string(json, 'reminder_occurrence_id'),
      templateId: _string(json, 'reminder_template_id'),
      patientId: _string(json, 'patient_id'),
      title: _string(json, 'title'),
      instructions: _optionalString(json, 'instructions'),
      category: ReminderCategory.parse(json['category']),
      priority: ReminderPriority.parse(json['priority']),
      scheduledAt: _dateTime(json, 'scheduled_at'),
      dueAt: _dateTime(json, 'due_at'),
      status: ReminderOccurrenceStatus.parse(json['status']),
      snoozeAllowed: _boolean(json, 'snooze_allowed'),
      defaultSnoozeMinutes: _integer(json, 'default_snooze_minutes'),
      missedAfterMinutes: _integer(json, 'missed_after_minutes'),
    ));
  }
}

class ReminderTemplateDto {
  const ReminderTemplateDto(this.value);
  final ReminderTemplate value;

  factory ReminderTemplateDto.fromJson(Map<String, dynamic> json) {
    final archivedText = _optionalString(json, 'archived_at');
    final archived = archivedText == null ? null : DateTime.tryParse(archivedText);
    if (archivedText != null && (archived == null || !archived.isUtc)) {
      throw const FormatException('archived_at must be an ISO-8601 UTC datetime or null.');
    }
    return ReminderTemplateDto(ReminderTemplate(
      id: _string(json, 'reminder_template_id'),
      patientId: _string(json, 'patient_id'),
      createdByUserId: _string(json, 'created_by_user_id'),
      title: _string(json, 'title'),
      category: ReminderCategory.parse(json['category']),
      instructions: _optionalString(json, 'instructions'),
      priority: ReminderPriority.parse(json['priority']),
      startDate: _string(json, 'start_date'),
      startTime: _string(json, 'start_time'),
      timezone: _string(json, 'timezone'),
      scheduleRule: _optionalString(json, 'schedule_rule'),
      dueAfterMinutes: _integer(json, 'due_after_minutes'),
      snoozeAllowed: _boolean(json, 'snooze_allowed'),
      defaultSnoozeMinutes: _integer(json, 'default_snooze_minutes'),
      missedAfterMinutes: _integer(json, 'missed_after_minutes'),
      notificationChannel: ReminderNotificationChannel.parse(json['notification_channels']),
      status: ReminderTemplateStatus.parse(json['status']),
      createdAt: _dateTime(json, 'created_at'),
      updatedAt: _dateTime(json, 'updated_at'),
      archivedAt: archived,
    ));
  }
}

ReminderPage<T> parseReminderPage<T>(
  Object? decoded,
  T Function(Map<String, dynamic>) parseItem,
) {
  if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
    throw const FormatException('Reminder page must contain an items list.');
  }
  final items = (decoded['items'] as List).map((item) {
    if (item is! Map<String, dynamic>) throw const FormatException('Reminder item must be an object.');
    return parseItem(item);
  }).toList(growable: false);
  return ReminderPage<T>(
    items: items,
    total: _integer(decoded, 'total'),
    limit: _integer(decoded, 'limit'),
    offset: _integer(decoded, 'offset'),
  );
}
