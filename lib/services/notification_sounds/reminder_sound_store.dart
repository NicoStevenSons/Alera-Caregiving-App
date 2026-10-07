import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'notification_sound_catalog.dart';

/// Persists the user's reminder sound on this device.
///
/// Uses secure storage like the app's other local settings (it also works in
/// the background-message isolate, where `shared_preferences` would not be
/// registered).
abstract interface class ReminderSoundStore {
  Future<ReminderSound> read();
  Future<void> write(ReminderSound sound);
}

class SecureReminderSoundStore implements ReminderSoundStore {
  SecureReminderSoundStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String storageKey = 'alera_reminder_sound_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<ReminderSound> read() async {
    try {
      return ReminderSound.parse(await _storage.read(key: storageKey));
    } catch (_) {
      return ReminderSound.defaultSound;
    }
  }

  @override
  Future<void> write(ReminderSound sound) =>
      _storage.write(key: storageKey, value: sound.id);
}

/// In-memory store for tests and previews.
class MemoryReminderSoundStore implements ReminderSoundStore {
  MemoryReminderSoundStore([this._sound = ReminderSound.defaultSound]);

  ReminderSound _sound;

  @override
  Future<ReminderSound> read() async => _sound;

  @override
  Future<void> write(ReminderSound sound) async => _sound = sound;
}

/// Store used when notifications are shown or scheduled (including from the
/// background-message isolate). Replaceable in tests.
ReminderSoundStore reminderSoundStore = SecureReminderSoundStore();
