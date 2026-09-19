import '../models/steps_data.dart';
import '../models/sleep_data.dart';

class ActivityDataMapper {
  const ActivityDataMapper._();

  static Map<String, dynamic> mapSteps({
    required String patientId,
    required StepsData data,
    DateTime? now,
  }) {
    final DateTime localNow = now ?? DateTime.now();

    final List<_ParsedStepSession> validSessions = [];

    for (final session in data.sessions) {
      if (session.stepCount <= 0) {
        continue;
      }

      final DateTime? start =
          DateTime.tryParse(session.startTime);

      final DateTime? end =
          DateTime.tryParse(session.endTime);

      if (start == null || end == null) {
        continue;
      }

      validSessions.add(
        _ParsedStepSession(
          stepCount: session.stepCount,
          start: start,
          end: end,
        ),
      );
    }

    validSessions.sort(
      (a, b) => a.start.compareTo(b.start),
    );

    final DateTime? firstMovement =
        validSessions.isEmpty
            ? null
            : validSessions.first.start;

    final DateTime? lastMovement =
        validSessions.isEmpty
            ? null
            : validSessions
                .map((session) => session.end)
                .reduce(
                  (a, b) =>
                      a.isAfter(b) ? a : b,
                );

    return {
      'patient_id': patientId,
      'activity_date': _formatDate(localNow),
      'activity_type': 'STEPS',

      'daily': {
        'total_steps': data.totalSteps,
        'first_movement_at':
            firstMovement
                ?.toUtc()
                .toIso8601String(),
        'last_movement_at':
            lastMovement
                ?.toUtc()
                .toIso8601String(),
      },

      'sessions': validSessions
          .map(
            (session) => {
              'external_session_id':
                  'hc-steps-'
                  '${session.start.toUtc().millisecondsSinceEpoch}-'
                  '${session.end.toUtc().millisecondsSinceEpoch}',
              'started_at':
                  session.start
                      .toUtc()
                      .toIso8601String(),
              'ended_at':
                  session.end
                      .toUtc()
                      .toIso8601String(),
              'steps': session.stepCount,
              'source': 'HEALTH_CONNECT',
            },
          )
          .toList(),
    };
  }

  static List<Map<String, dynamic>> mapSleep({
  required String patientId,
  required SleepData data,
}) {
  final Map<String, List<_ParsedSleepSession>>
      sessionsByDate = {};

  for (final session in data.sessions) {
    final DateTime? start =
        DateTime.tryParse(session.startTime);

    final DateTime? end =
        DateTime.tryParse(session.endTime);

    if (start == null || end == null) {
      continue;
    }

    if (end.isBefore(start)) {
      continue;
    }

    final DateTime localStart =
        start.toLocal();

    final String activityDate =
        _formatDate(localStart);

    sessionsByDate
        .putIfAbsent(
          activityDate,
          () => <_ParsedSleepSession>[],
        )
        .add(
          _ParsedSleepSession(
            start: start,
            end: end,
          ),
        );
  }

  final List<Map<String, dynamic>> payloads = [];

  for (final entry in sessionsByDate.entries) {
    final String activityDate = entry.key;
    final List<_ParsedSleepSession> sessions =
        entry.value;

    payloads.add({
      'patient_id': patientId,
      'activity_date': activityDate,
      'activity_type': 'SLEEP',
      'sessions': sessions
          .map(
            (session) => {
              'external_session_id':
                  'hc-sleep-'
                  '${session.start.toUtc().millisecondsSinceEpoch}',

              'sleep_type': 'UNKNOWN',

              'started_at':
                  session.start
                      .toUtc()
                      .toIso8601String(),

              'ended_at':
                  session.end
                      .toUtc()
                      .toIso8601String(),

              'source': 'HEALTH_CONNECT',
            },
          )
          .toList(),
    });
  }

  return payloads;
}

  static String _formatDate(DateTime date) {
    final String year =
        date.year.toString().padLeft(4, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    final String day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }


}

class _ParsedStepSession {
  final int stepCount;
  final DateTime start;
  final DateTime end;

  const _ParsedStepSession({
    required this.stepCount,
    required this.start,
    required this.end,
  });
}

class _ParsedSleepSession {
  final DateTime start;
  final DateTime end;

  const _ParsedSleepSession({
    required this.start,
    required this.end,
  });
}