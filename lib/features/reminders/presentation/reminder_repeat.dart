import 'package:flutter/material.dart' show TimeOfDay;

enum ReminderRepeatMode { once, weekdays, custom }

/// How often a new reminder repeats. Days use [DateTime.monday] (1) through
/// [DateTime.sunday] (7).
///
/// NOTE: the backend stores the repeat as an opaque `schedule_rule` string
/// whose format isn't documented anywhere in this repo. [rule] emits
/// iCalendar-style RRULE text (the most common convention) - if the backend
/// expects something else, [rule] is the only place that needs to change.
/// "Once" sends no rule at all, exactly as before.
class ReminderRepeat {
  const ReminderRepeat({
    this.mode = ReminderRepeatMode.once,
    this.customDays = const {},
  });

  final ReminderRepeatMode mode;
  final Set<int> customDays;

  static const weekdayDays = {1, 2, 3, 4, 5};
  static const _codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  Set<int> get days => switch (mode) {
    ReminderRepeatMode.once => const {},
    ReminderRepeatMode.weekdays => weekdayDays,
    ReminderRepeatMode.custom => customDays,
  };

  bool get isValid =>
      mode != ReminderRepeatMode.custom || customDays.isNotEmpty;

  bool get repeats => mode != ReminderRepeatMode.once;

  String? get rule {
    if (!repeats || !isValid) return null;
    if (days.length == 7) return 'FREQ=DAILY';
    final sorted = days.toList()..sort();
    return 'FREQ=WEEKLY;BYDAY=${sorted.map((d) => _codes[d - 1]).join(',')}';
  }

  bool allows(DateTime day) => !repeats || days.contains(day.weekday);

  ReminderRepeat copyWith({
    ReminderRepeatMode? mode,
    Set<int>? customDays,
  }) => ReminderRepeat(
    mode: mode ?? this.mode,
    customDays: customDays ?? this.customDays,
  );
}

DateTime _at(DateTime day, TimeOfDay time) =>
    DateTime(day.year, day.month, day.day, time.hour, time.minute);

/// The first moment this reminder will fire, or null if it never will
/// (a one-off in the past, or a repeat with no days).
DateTime? reminderNextFire({
  required ReminderRepeat repeat,
  required DateTime startDate,
  required TimeOfDay time,
  required DateTime now,
}) {
  if (!repeat.repeats) {
    final at = _at(startDate, time);
    return at.isAfter(now) ? at : null;
  }
  if (!repeat.isValid) return null;
  final today = DateTime(now.year, now.month, now.day);
  final first = startDate.isAfter(today) ? startDate : today;
  for (var i = 0; i < 14; i++) {
    final day = DateTime(first.year, first.month, first.day + i);
    if (!repeat.allows(day)) continue;
    final at = _at(day, time);
    if (at.isAfter(now)) return at;
  }
  return null;
}

/// "Reminds in 1 day 2 hours", like the clock app's "Ring in 1 day".
String reminderUntilText(DateTime? fire, DateTime now) {
  if (fire == null) return 'That time has already passed';
  final diff = fire.difference(now);
  final days = diff.inDays;
  final hours = diff.inHours.remainder(24);
  final minutes = diff.inMinutes.remainder(60);
  String unit(int n, String s) => '$n $s${n == 1 ? '' : 's'}';
  if (days > 0) {
    return 'Reminds in ${unit(days, 'day')}'
        '${hours > 0 ? ' ${unit(hours, 'hour')}' : ''}';
  }
  if (hours > 0) {
    return 'Reminds in ${unit(hours, 'hour')}'
        '${minutes > 0 ? ' ${unit(minutes, 'minute')}' : ''}';
  }
  if (minutes > 0) return 'Reminds in ${unit(minutes, 'minute')}';
  return 'Reminds in less than a minute';
}
