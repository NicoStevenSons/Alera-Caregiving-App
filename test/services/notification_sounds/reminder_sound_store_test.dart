import 'package:alera/services/notification_sounds/notification_sound_catalog.dart';
import 'package:alera/services/notification_sounds/reminder_sound_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to the chime and round-trips every sound', () async {
    final store = MemoryReminderSoundStore();
    expect(await store.read(), ReminderSound.defaultSound);

    for (final sound in ReminderSound.values) {
      await store.write(sound);
      expect(await store.read(), sound);
    }
  });

  test('storage key is stable and versioned', () {
    expect(SecureReminderSoundStore.storageKey, 'alera_reminder_sound_v1');
  });
}
