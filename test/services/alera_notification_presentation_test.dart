import 'package:alera/services/alera_notification_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes every supported notification type to its own channel', () {
    expect(
      AleraNotificationPresentation.fromData({'type': 'ALERT'}).channelId,
      'alera_alerts_v2',
    );
    expect(
      AleraNotificationPresentation.fromData({'type': 'REMINDER'}).channelId,
      'alera_caregiver_reminders_v2',
    );
    expect(
      AleraNotificationPresentation.fromData({'type': 'NUDGE'}).channelId,
      'alera_nudges_v2',
    );
    expect(
      AleraNotificationPresentation.fromData({
        'type': 'DEVICE_STATUS',
      }).channelId,
      'alera_device_status_v2',
    );
  });

  test('only due reminders receive complete and snooze actions', () {
    expect(
      AleraNotificationPresentation.fromData({
        'type': 'REMINDER_DUE',
      }).hasReminderActions,
      isTrue,
    );
    expect(
      AleraNotificationPresentation.fromData({
        'type': 'ALERT',
      }).hasReminderActions,
      isFalse,
    );
  });

  test('unknown events still use the general heads-up channel', () {
    final presentation = AleraNotificationPresentation.fromData({
      'type': 'SOMETHING_NEW',
    });
    expect(presentation.kind, AleraNotificationKind.general);
    expect(presentation.fallbackTitle, 'Alera');
  });
}
