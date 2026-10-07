import 'dart:io';

import 'package:alera/services/notification_sounds/notification_channels.dart';
import 'package:alera/services/notification_sounds/notification_sound_catalog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlertSoundCategory.fromPayload', () {
    test('critical severity maps to the critical alert sound', () {
      expect(
        AlertSoundCategory.fromPayload({
          'type': 'ALERT',
          'severity': 'CRITICAL',
        }),
        AlertSoundCategory.criticalAlert,
      );
    });

    test('warning and missing severity map to the warning alert sound', () {
      expect(
        AlertSoundCategory.fromPayload({
          'type': 'ALERT',
          'severity': 'WARNING',
        }),
        AlertSoundCategory.warningAlert,
      );
      expect(
        AlertSoundCategory.fromPayload({'type': 'ALERT'}),
        AlertSoundCategory.warningAlert,
      );
    });

    test('help requests always use the help request sound', () {
      expect(
        AlertSoundCategory.fromPayload({'type': 'HELP_REQUEST'}),
        AlertSoundCategory.helpRequest,
      );
    });

    test('device/system alerts use the device status sound', () {
      expect(
        AlertSoundCategory.fromPayload({
          'type': 'ALERT',
          'metric_type': 'SYSTEM',
          'severity': 'CRITICAL',
        }),
        AlertSoundCategory.deviceStatus,
      );
      expect(
        AlertSoundCategory.fromPayload({
          'type': 'ALERT',
          'alert_category': 'DEVICE_STATUS',
        }),
        AlertSoundCategory.deviceStatus,
      );
    });

    test('missed reminder escalation has its own sound', () {
      expect(
        AlertSoundCategory.fromPayload({
          'type': 'ALERT',
          'alert_category': 'MISSED_REMINDER',
          'severity': 'WARNING',
        }),
        AlertSoundCategory.missedReminder,
      );
    });

    test('explicit sound_category wins and is case-insensitive', () {
      expect(
        AlertSoundCategory.fromPayload({
          'type': 'ALERT',
          'severity': 'WARNING',
          'sound_category': ' critical ',
        }),
        AlertSoundCategory.criticalAlert,
      );
    });

    test('non-alert payloads have no fixed category', () {
      expect(AlertSoundCategory.fromPayload({'type': 'REMINDER_DUE'}), isNull);
      expect(AlertSoundCategory.fromPayload({'type': 'NUDGE'}), isNull);
      expect(AlertSoundCategory.fromPayload({}), isNull);
    });
  });

  group('ReminderSound', () {
    test('parse falls back to the default for unknown values', () {
      expect(ReminderSound.parse(null), ReminderSound.defaultSound);
      expect(ReminderSound.parse('nope'), ReminderSound.defaultSound);
      expect(ReminderSound.parse('bell'), ReminderSound.bell);
      expect(ReminderSound.parse('vibrate'), ReminderSound.vibrateOnly);
    });

    test('persisted ids round-trip for every sound', () {
      for (final sound in ReminderSound.values) {
        expect(ReminderSound.parse(sound.id), sound);
      }
    });

    test('vibrate only and silent behave correctly', () {
      expect(ReminderSound.vibrateOnly.playsSound, isFalse);
      expect(ReminderSound.vibrateOnly.vibrates, isTrue);
      expect(ReminderSound.silent.playsSound, isFalse);
      expect(ReminderSound.silent.vibrates, isFalse);
      expect(ReminderSound.chime.playsSound, isTrue);
    });
  });

  group('channel ids', () {
    final ids = <String>[
      for (final c in AlertSoundCategory.values) c.channelId,
      for (final s in ReminderSound.values) s.channelId,
    ];

    test('are unique and versioned', () {
      expect(ids.toSet().length, ids.length);
      for (final id in ids) {
        expect(id, matches(RegExp(r'^alera_[a-z_]+_v\d+$')));
      }
    });

    test('do not collide with legacy channels', () {
      const legacy = {
        legacyAlertsChannelId,
        legacyPatientRemindersChannelId,
        legacyNudgesChannelId,
        'alera_help_requests',
        'alera_reminders',
      };
      expect(ids.toSet().intersection(legacy), isEmpty);
    });
  });

  group('channel definitions', () {
    test('every alert channel plays its own bundled sound', () {
      for (final category in AlertSoundCategory.values) {
        final channel = alertChannel(category);
        expect(channel.id, category.channelId);
        expect(channel.playSound, isTrue);
        expect(
          (channel.sound as RawResourceAndroidNotificationSound).sound,
          category.rawResource,
        );
      }
    });

    test('critical categories use maximum importance', () {
      expect(
        alertChannel(AlertSoundCategory.criticalAlert).importance,
        Importance.max,
      );
      expect(
        alertChannel(AlertSoundCategory.helpRequest).importance,
        Importance.max,
      );
      expect(
        alertChannel(AlertSoundCategory.deviceStatus).importance,
        Importance.high,
      );
    });

    test('reminder channels follow the selected sound', () {
      final chime = reminderChannel(ReminderSound.chime);
      expect(chime.playSound, isTrue);
      expect(chime.enableVibration, isTrue);

      final vibrate = reminderChannel(ReminderSound.vibrateOnly);
      expect(vibrate.playSound, isFalse);
      expect(vibrate.enableVibration, isTrue);
      expect(vibrate.sound, isNull);

      final silent = reminderChannel(ReminderSound.silent);
      expect(silent.playSound, isFalse);
      expect(silent.enableVibration, isFalse);
      expect(silent.importance, Importance.defaultImportance);
    });

    test('notification details use the same channel as the definition', () {
      for (final sound in ReminderSound.values) {
        expect(reminderAndroidDetails(sound).channelId, sound.channelId);
      }
      for (final category in AlertSoundCategory.values) {
        expect(alertAndroidDetails(category).channelId, category.channelId);
      }
    });
  });

  test('every bundled sound resource exists in android res/raw', () {
    final resources = <String>[
      for (final c in AlertSoundCategory.values) c.rawResource,
      for (final s in ReminderSound.values)
        if (s.rawResource != null) s.rawResource!,
    ];
    for (final name in resources) {
      expect(
        File('android/app/src/main/res/raw/$name.wav').existsSync(),
        isTrue,
        reason: '$name.wav is missing',
      );
    }
  });
}
