/// Notification sound definitions.
///
/// Alert sounds are fixed by category and are NOT user-selectable. Only
/// ordinary reminders use [ReminderSound].
///
/// Channel IDs are versioned (`_v1`). Android cannot reliably change a
/// channel's sound after it is created, so a new sound means a new ID
/// (`_v2`, ...), never an edit.
library;

/// Fixed-sound notification categories.
enum AlertSoundCategory {
  warningAlert(
    channelId: 'alera_alert_warning_v1',
    channelName: 'Warning alerts',
    description: 'Health alerts that need attention',
    rawResource: 'alera_alert_warning',
    urgent: false,
  ),
  criticalAlert(
    channelId: 'alera_alert_critical_v1',
    channelName: 'Critical alerts',
    description: 'Urgent health alerts',
    rawResource: 'alera_alert_critical',
    urgent: true,
  ),
  helpRequest(
    channelId: 'alera_help_request_v1',
    channelName: 'Help requests',
    description: 'A patient is asking for help',
    rawResource: 'alera_help_request',
    urgent: true,
  ),
  deviceStatus(
    channelId: 'alera_device_status_v1',
    channelName: 'Device and system status',
    description: 'Watch connection, battery and system updates',
    rawResource: 'alera_device_status',
    urgent: false,
  ),
  missedReminder(
    channelId: 'alera_missed_reminder_v1',
    channelName: 'Missed reminders',
    description: 'A patient missed a reminder',
    rawResource: 'alera_missed_reminder',
    urgent: true,
  );

  const AlertSoundCategory({
    required this.channelId,
    required this.channelName,
    required this.description,
    required this.rawResource,
    required this.urgent,
  });

  final String channelId;
  final String channelName;
  final String description;
  final String rawResource;

  /// Urgent categories use the highest Android importance.
  final bool urgent;

  static final Set<String> channelIds = {
    for (final AlertSoundCategory c in values) c.channelId,
  };

  /// Chooses the fixed category for an FCM data payload.
  ///
  /// Resolution order:
  ///  1. `sound_category` (explicit, set by the backend).
  ///  2. `type == HELP_REQUEST`.
  ///  3. `type == ALERT`: `alert_category` (MISSED_REMINDER / DEVICE_STATUS),
  ///     then `metric_type` for device/system alerts, then `severity`.
  ///
  /// An ALERT with no usable severity falls back to [warningAlert].
  /// Returns null for payloads that are not alert-like.
  static AlertSoundCategory? fromPayload(Map<String, dynamic> data) {
    final String? explicit = _norm(data['sound_category']);
    switch (explicit) {
      case 'WARNING':
      case 'WARNING_ALERT':
        return warningAlert;
      case 'CRITICAL':
      case 'CRITICAL_ALERT':
        return criticalAlert;
      case 'HELP_REQUEST':
        return helpRequest;
      case 'DEVICE_STATUS':
      case 'SYSTEM':
        return deviceStatus;
      case 'MISSED_REMINDER':
        return missedReminder;
    }

    final String? type = _norm(data['type']);
    if (type == 'HELP_REQUEST') return helpRequest;
    if (type != 'ALERT') return null;

    switch (_norm(data['alert_category'])) {
      case 'MISSED_REMINDER':
        return missedReminder;
      case 'DEVICE_STATUS':
      case 'SYSTEM':
        return deviceStatus;
    }

    switch (_norm(data['metric_type'])) {
      case 'SYSTEM':
      case 'DEVICE':
      case 'DEVICE_STATUS':
        return deviceStatus;
    }

    switch (_norm(data['severity'])) {
      case 'CRITICAL':
      case 'HIGH':
      case 'URGENT':
        return criticalAlert;
      default:
        return warningAlert;
    }
  }

  static String? _norm(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed.toUpperCase();
  }
}

/// The only user-selectable sound setting: how ordinary reminders sound.
enum ReminderSound {
  chime(
    id: 'chime',
    label: 'Chime',
    description: 'Two bright, rising notes',
    rawResource: 'alera_reminder_chime',
  ),
  bell(
    id: 'bell',
    label: 'Bell',
    description: 'A single clear bell',
    rawResource: 'alera_reminder_bell',
  ),
  marimba(
    id: 'marimba',
    label: 'Marimba',
    description: 'Three quick, warm taps',
    rawResource: 'alera_reminder_marimba',
  ),
  breeze(
    id: 'breeze',
    label: 'Breeze',
    description: 'A soft, gentle rise',
    rawResource: 'alera_reminder_breeze',
  ),
  pulse(
    id: 'pulse',
    label: 'Pulse',
    description: 'Three steady beats',
    rawResource: 'alera_reminder_pulse',
  ),
  vibrateOnly(
    id: 'vibrate',
    label: 'Vibrate only',
    description: 'No sound, the phone vibrates',
    rawResource: null,
  ),
  silent(
    id: 'silent',
    label: 'Silent',
    description: 'No sound and no vibration',
    rawResource: null,
  );

  const ReminderSound({
    required this.id,
    required this.label,
    required this.description,
    required this.rawResource,
  });

  /// Stable value persisted on the device. Never rename.
  final String id;
  final String label;
  final String description;

  /// Bundled `res/raw` file name (no extension), or null when there is no
  /// sound to play.
  final String? rawResource;

  bool get playsSound => rawResource != null;
  bool get vibrates => this != silent;

  String get channelId => 'alera_reminder_${id}_v1';

  static const ReminderSound defaultSound = chime;

  static ReminderSound parse(String? id) {
    for (final ReminderSound sound in values) {
      if (sound.id == id) return sound;
    }
    return defaultSound;
  }
}
