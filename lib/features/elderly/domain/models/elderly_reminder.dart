import '../../../reminders/domain/reminder_models.dart';

class ElderlyReminder {
  final String occurrenceId;
  final String templateId;
  final String patientId;

  final String title;
  final String? instructions;
  final String category;
  final String priority;

  final DateTime scheduledAt;
  final DateTime dueAt;

  final String status;

  final bool snoozeAllowed;
  final int defaultSnoozeMinutes;

  const ElderlyReminder({
    required this.occurrenceId,
    required this.templateId,
    required this.patientId,
    required this.title,
    this.instructions,
    required this.category,
    required this.priority,
    required this.scheduledAt,
    required this.dueAt,
    required this.status,
    required this.snoozeAllowed,
    required this.defaultSnoozeMinutes,
  });

  factory ElderlyReminder.fromOccurrence(ReminderOccurrence occurrence) {
    return ElderlyReminder(
      occurrenceId: occurrence.id,
      templateId: occurrence.templateId,
      patientId: occurrence.patientId,
      title: occurrence.title,
      instructions: occurrence.instructions,
      category: occurrence.category.apiValue,
      priority: occurrence.priority.apiValue,
      scheduledAt: occurrence.scheduledAt,
      dueAt: occurrence.dueAt,
      status: occurrence.status.apiValue,
      snoozeAllowed: occurrence.snoozeAllowed,
      defaultSnoozeMinutes: occurrence.defaultSnoozeMinutes,
    );
  }

  factory ElderlyReminder.fromSupabase(Map<String, dynamic> json) {
    final template = json['reminder_templates'] as Map<String, dynamic>;

    return ElderlyReminder(
      occurrenceId: json['reminder_occurrence_id'] as String,

      templateId: json['reminder_template_id'] as String,

      patientId: template['patient_id'] as String,

      title: template['title'] as String,

      instructions: template['instructions'] as String?,

      category: template['category'] as String,

      priority: template['priority'] as String,

      scheduledAt: DateTime.parse(json['scheduled_at'] as String),

      dueAt: DateTime.parse(json['due_at'] as String),

      status: json['status'] as String,

      snoozeAllowed: template['snooze_allowed'] as bool,

      defaultSnoozeMinutes: template['default_snooze_minutes'] as int,
    );
  }
}
