import 'package:alera/features/reminders/data/reminder_api_data_source.dart';
import 'package:alera/features/reminders/data/reminder_controller.dart';
import 'package:alera/features/reminders/domain/reminder_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads templates and occurrences for the selected patient', () async {
    final source = _Source();
    final controller = ReminderController(dataSource: source);

    await controller.loadForPatient('patient-a');

    expect(source.patientIds, ['patient-a', 'patient-a']);
    expect(controller.loading, isFalse);
    expect(controller.errorMessage, isNull);
    expect(controller.occurrences.single.id, 'occurrence-id');
    expect(controller.templates.single.id, 'template-id');
  });

  test('action updates only the matching occurrence', () async {
    final source = _Source();
    final controller = ReminderController(dataSource: source);
    await controller.loadForPatient('patient-a');

    await controller.complete('occurrence-id');

    expect(controller.occurrences.single.status, ReminderOccurrenceStatus.completed);
    expect(controller.isBusy('occurrence-id'), isFalse);
  });
}

class _Source implements ReminderDataSource {
  final List<String> patientIds = [];

  @override
  Future<ReminderPage<ReminderOccurrence>> fetchOccurrences({
    String? patientId,
    List<ReminderOccurrenceStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  }) async {
    patientIds.add(patientId!);
    return ReminderPage(items: [_occurrence()], total: 1, limit: limit, offset: offset);
  }

  @override
  Future<ReminderPage<ReminderTemplate>> fetchTemplates(
    String patientId, {
    List<ReminderTemplateStatus> statuses = const [],
    int limit = 100,
    int offset = 0,
  }) async {
    patientIds.add(patientId);
    return ReminderPage(items: [_template()], total: 1, limit: limit, offset: offset);
  }

  @override
  Future<ReminderActionResult> complete(String occurrenceId, {String? note}) async =>
      ReminderActionResult(reminder: _occurrence(status: ReminderOccurrenceStatus.completed), idempotent: false);

  @override
  Future<ReminderActionResult> snooze(String occurrenceId, {int? snoozeMinutes, String? note}) async =>
      ReminderActionResult(reminder: _occurrence(status: ReminderOccurrenceStatus.snoozed), idempotent: false);

  @override Future<ReminderTemplate> archiveTemplate(String templateId) async => _template();
  @override Future<ReminderTemplate> createTemplate(ReminderTemplateDraft draft) async => _template();
  @override Future<ReminderTemplate> updateTemplate(String templateId, Map<String, Object?> changes) async => _template();
}

ReminderOccurrence _occurrence({
  ReminderOccurrenceStatus status = ReminderOccurrenceStatus.due,
}) => ReminderOccurrence(
  id: 'occurrence-id', templateId: 'template-id', patientId: 'patient-a',
  title: 'Medication', category: ReminderCategory.medication,
  priority: ReminderPriority.high,
  scheduledAt: DateTime.utc(2026, 9, 17, 12),
  dueAt: DateTime.utc(2026, 9, 17, 12, 15), status: status,
  snoozeAllowed: true, defaultSnoozeMinutes: 10, missedAfterMinutes: 30,
);

ReminderTemplate _template() => ReminderTemplate(
  id: 'template-id', patientId: 'patient-a', createdByUserId: 'caregiver-id',
  title: 'Medication', category: ReminderCategory.medication,
  priority: ReminderPriority.high, startDate: '2026-09-17', startTime: '20:00:00',
  timezone: 'Asia/Manila', dueAfterMinutes: 15, snoozeAllowed: true,
  defaultSnoozeMinutes: 10, missedAfterMinutes: 30,
  notificationChannel: ReminderNotificationChannel.push,
  status: ReminderTemplateStatus.active,
  createdAt: DateTime.utc(2026, 9, 17), updatedAt: DateTime.utc(2026, 9, 17),
);
