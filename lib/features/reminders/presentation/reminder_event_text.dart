import '../domain/reminder_event.dart';
import 'reminder_formatters.dart';

/// "Oct 7, 2026 · 7:00 AM", in the device's local time.
String reminderEventWhen(DateTime value) {
  final local = value.toLocal();
  return '${reminderShortDate(local)} · ${reminderClock(local)}';
}

/// Caregiver wording for an event.
String caregiverEventLabel(ReminderEvent event) => switch (event.type) {
  ReminderEventType.created => 'Created',
  ReminderEventType.notificationSent => 'Notification sent',
  ReminderEventType.snoozed => 'Snoozed',
  ReminderEventType.completed => 'Completed',
  ReminderEventType.completedLate => 'Completed late',
  ReminderEventType.completedOnBehalf => 'Completed by caregiver',
  ReminderEventType.canceled => 'Canceled',
  ReminderEventType.markedMissed => 'Marked missed',
  ReminderEventType.unknown =>
    event.rawType == null ? 'Update' : reminderTitleCase(event.rawType!),
};

/// Who did it, for the caregiver view.
String? caregiverEventActor(ReminderEvent event) {
  final name = event.actorDisplayName;
  if (name != null) return name;
  return switch (event.actorRole) {
    ReminderActorRole.caregiver => 'Caregiver',
    ReminderActorRole.patient => 'Patient',
    ReminderActorRole.system => 'Alera',
    ReminderActorRole.unknown => null,
  };
}

/// Meaningful secondary lines only: never raw metadata.
List<String> caregiverEventDetails(ReminderEvent event) {
  final lines = <String>[];
  if (event.type == ReminderEventType.snoozed) {
    final until = event.snoozedUntil;
    if (until != null) lines.add('Until ${reminderClock(until)}');
  }
  if (event.type == ReminderEventType.notificationSent) {
    final parts = [
      if (_audience(event.audience) case final audience?) audience,
      if (_channel(event.channel) case final channel?) channel,
    ];
    if (parts.isNotEmpty) lines.add(parts.join(' · '));
  }
  return lines;
}

String? _audience(String? value) => switch (value?.toUpperCase()) {
  'PATIENT' => 'Sent to patient',
  'CAREGIVER' || 'CAREGIVERS' => 'Sent to caregivers',
  _ => null,
};

String? _channel(String? value) => switch (value?.toUpperCase()) {
  'PUSH' => 'Push notification',
  'IN_APP' => 'In-app',
  'SMS' => 'SMS',
  _ => null,
};

/// Plain wording for the elderly patient.
String elderlyEventLabel(ReminderEvent event) {
  final byPatient = event.actorRole == ReminderActorRole.patient;
  return switch (event.type) {
    ReminderEventType.created => 'Reminder set up',
    ReminderEventType.notificationSent => 'You were reminded',
    ReminderEventType.snoozed => byPatient ? 'You snoozed it' : 'Snoozed',
    ReminderEventType.completed => byPatient ? 'You finished this' : 'Done',
    ReminderEventType.completedLate => 'Done, a little late',
    ReminderEventType.completedOnBehalf => 'Marked done for you',
    ReminderEventType.canceled => 'Canceled',
    ReminderEventType.markedMissed => 'Missed',
    ReminderEventType.unknown => 'Update',
  };
}

String? elderlyEventActor(ReminderEvent event) {
  final name = event.actorDisplayName;
  return switch (event.actorRole) {
    ReminderActorRole.patient => 'You',
    ReminderActorRole.system => name ?? 'Alera',
    ReminderActorRole.caregiver => name ?? 'Your caregiver',
    ReminderActorRole.unknown => name,
  };
}

List<String> elderlyEventDetails(ReminderEvent event) {
  if (event.type != ReminderEventType.snoozed) return const [];
  final until = event.snoozedUntil;
  return until == null ? const [] : ['Until ${reminderClock(until)}'];
}
