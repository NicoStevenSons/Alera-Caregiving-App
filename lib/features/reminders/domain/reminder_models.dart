enum ReminderCategory {
  medication('MEDICATION'), healthCheck('HEALTH_CHECK'), hydration('HYDRATION'),
  meal('MEAL'), mobility('MOBILITY'), appointment('APPOINTMENT'),
  checkIn('CHECK_IN'), deviceTask('DEVICE_TASK'), other('OTHER');

  const ReminderCategory(this.apiValue);
  final String apiValue;
  static ReminderCategory parse(Object? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => throw const FormatException('Unknown reminder category.'),
  );
}

enum ReminderPriority {
  low('LOW'), normal('NORMAL'), high('HIGH');
  const ReminderPriority(this.apiValue);
  final String apiValue;
  static ReminderPriority parse(Object? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => throw const FormatException('Unknown reminder priority.'),
  );
}

enum ReminderOccurrenceStatus {
  upcoming('UPCOMING'), due('DUE'), snoozed('SNOOZED'),
  completed('COMPLETED'), missed('MISSED'), canceled('CANCELED'),
  completedLate('COMPLETED_LATE');
  const ReminderOccurrenceStatus(this.apiValue);
  final String apiValue;
  static ReminderOccurrenceStatus parse(Object? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => throw const FormatException('Unknown reminder status.'),
  );
}

enum ReminderTemplateStatus {
  active('ACTIVE'), disabled('DISABLED'), archived('ARCHIVED');
  const ReminderTemplateStatus(this.apiValue);
  final String apiValue;
  static ReminderTemplateStatus parse(Object? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => throw const FormatException('Unknown template status.'),
  );
}

enum ReminderNotificationChannel {
  inApp('IN_APP'), push('PUSH'), sms('SMS');
  const ReminderNotificationChannel(this.apiValue);
  final String apiValue;
  static ReminderNotificationChannel parse(Object? value) => values.firstWhere(
    (item) => item.apiValue == value,
    orElse: () => throw const FormatException('Unknown notification channel.'),
  );
}

class ReminderOccurrence {
  const ReminderOccurrence({
    required this.id, required this.templateId, required this.patientId,
    required this.title, required this.category, required this.priority,
    required this.scheduledAt, required this.dueAt, required this.status,
    required this.snoozeAllowed, required this.defaultSnoozeMinutes,
    required this.missedAfterMinutes, this.instructions,
  });
  final String id;
  final String templateId;
  final String patientId;
  final String title;
  final String? instructions;
  final ReminderCategory category;
  final ReminderPriority priority;
  final DateTime scheduledAt;
  final DateTime dueAt;
  final ReminderOccurrenceStatus status;
  final bool snoozeAllowed;
  final int defaultSnoozeMinutes;
  final int missedAfterMinutes;
}

class ReminderTemplate {
  const ReminderTemplate({
    required this.id, required this.patientId, required this.createdByUserId,
    required this.title, required this.category, required this.priority,
    required this.startDate, required this.startTime, required this.timezone,
    required this.dueAfterMinutes, required this.snoozeAllowed,
    required this.defaultSnoozeMinutes, required this.missedAfterMinutes,
    required this.notificationChannel, required this.status,
    required this.createdAt, required this.updatedAt,
    this.instructions, this.scheduleRule, this.archivedAt,
  });
  final String id;
  final String patientId;
  final String createdByUserId;
  final String title;
  final ReminderCategory category;
  final String? instructions;
  final ReminderPriority priority;
  final String startDate;
  final String startTime;
  final String timezone;
  final String? scheduleRule;
  final int dueAfterMinutes;
  final bool snoozeAllowed;
  final int defaultSnoozeMinutes;
  final int missedAfterMinutes;
  final ReminderNotificationChannel notificationChannel;
  final ReminderTemplateStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class ReminderPage<T> {
  const ReminderPage({required this.items, required this.total, required this.limit, required this.offset});
  final List<T> items;
  final int total;
  final int limit;
  final int offset;
}

class ReminderActionResult {
  const ReminderActionResult({required this.reminder, required this.idempotent});
  final ReminderOccurrence reminder;
  final bool idempotent;
}

class ReminderTemplateDraft {
  const ReminderTemplateDraft({
    required this.patientId, required this.title, required this.category,
    required this.startDate, required this.startTime,
    this.timezone = 'Asia/Manila', this.instructions,
    this.priority = ReminderPriority.normal, this.scheduleRule,
    this.dueAfterMinutes = 15, this.snoozeAllowed = true,
    this.defaultSnoozeMinutes = 10, this.missedAfterMinutes = 30,
    this.notificationChannel = ReminderNotificationChannel.push,
  });
  final String patientId;
  final String title;
  final ReminderCategory category;
  final String? instructions;
  final ReminderPriority priority;
  final String startDate;
  final String startTime;
  final String timezone;
  final String? scheduleRule;
  final int dueAfterMinutes;
  final bool snoozeAllowed;
  final int defaultSnoozeMinutes;
  final int missedAfterMinutes;
  final ReminderNotificationChannel notificationChannel;

  Map<String, Object?> toJson() => {
    'patient_id': patientId, 'title': title.trim(),
    'category': category.apiValue, 'instructions': instructions?.trim(),
    'priority': priority.apiValue, 'start_date': startDate,
    'start_time': startTime, 'timezone': timezone,
    'schedule_rule': scheduleRule, 'due_after_minutes': dueAfterMinutes,
    'snooze_allowed': snoozeAllowed,
    'default_snooze_minutes': defaultSnoozeMinutes,
    'missed_after_minutes': missedAfterMinutes,
    'notification_channels': notificationChannel.apiValue,
  };
}
