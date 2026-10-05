import 'package:flutter/material.dart' show TimeOfDay;

import '../domain/reminder_models.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String reminderWeekday(DateTime date, {bool short = false}) {
  final name = _weekdays[date.weekday - 1];
  return short ? name.substring(0, 3) : name;
}

/// "Monday, September 22"
String reminderLongDate(DateTime date) =>
    '${reminderWeekday(date)}, ${_months[date.month - 1]} ${date.day}';

/// "8:30 AM"
String reminderClock(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
}

/// "8 AM"
String reminderHourLabel(int hour) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h ${hour >= 12 ? 'PM' : 'AM'}';
}

/// "2025-09-22" - the date the API expects.
String reminderApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime reminderDayOf(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String reminderTitleCase(String value) => value
    .toLowerCase()
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');

/// The schedule rule is an opaque backend string, so this only recognises
/// the common frequencies and falls back to a generic "Repeats".
String? reminderRepeatLabel(ReminderTemplate? template) {
  final rule = template?.scheduleRule;
  if (template == null) return null;
  if (rule == null || rule.trim().isEmpty) return 'Once';
  final upper = rule.toUpperCase();
  if (upper.contains('DAILY')) return 'Daily';
  if (upper.contains('WEEKLY')) return 'Weekly';
  if (upper.contains('MONTHLY')) return 'Monthly';
  return 'Repeats';
}

String reminderCategoryAsset(ReminderCategory category) {
  final name = switch (category) {
    ReminderCategory.medication => 'medication',
    ReminderCategory.healthCheck => 'health_check',
    ReminderCategory.hydration => 'hydration',
    ReminderCategory.meal => 'meal',
    ReminderCategory.mobility => 'mobility',
    ReminderCategory.appointment => 'appointment',
    ReminderCategory.checkIn => 'check_in',
    ReminderCategory.deviceTask => 'device_task',
    ReminderCategory.other => 'other',
  };
  return 'alera-figma-assets/assets/icons/reminders/$name.svg';
}

/// "Oct 7, 2026"
String reminderShortDate(DateTime date) =>
    '${_months[date.month - 1].substring(0, 3)} ${date.day}, ${date.year}';

/// "12:23 PM"
String reminderTimeOfDay(TimeOfDay time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
}
