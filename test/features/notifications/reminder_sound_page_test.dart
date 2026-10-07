import 'package:alera/features/notifications/presentation/reminder_sound_page.dart';
import 'package:alera/services/notification_sounds/notification_sound_catalog.dart';
import 'package:alera/services/notification_sounds/notification_sound_preview.dart';
import 'package:alera/services/notification_sounds/reminder_sound_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePreview implements NotificationSoundPreview {
  final List<String> played = [];
  int stops = 0;

  @override
  Future<bool> playResource(String resource) async {
    played.add(resource);
    return true;
  }

  @override
  Future<void> stop() async => stops++;

  final List<String> opened = [];

  @override
  Future<bool> openChannelSettings(String channelId) async {
    opened.add(channelId);
    return true;
  }
}

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    MemoryReminderSoundStore store,
    _FakePreview preview,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: ReminderSoundPage(store: store, preview: preview)),
    );
    await tester.pump();
  }

  testWidgets('shows the saved selection', (tester) async {
    final store = MemoryReminderSoundStore(ReminderSound.bell);
    await pumpPage(tester, store, _FakePreview());

    expect(find.byKey(const Key('reminder-sound-bell')), findsOneWidget);
    final bellRow = find.descendant(
      of: find.byKey(const Key('reminder-sound-bell')),
      matching: find.byIcon(Icons.check_circle),
    );
    expect(bellRow, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('reminder-sound-chime')),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsNothing,
    );
  });

  testWidgets('selecting a sound persists it and plays a preview', (
    tester,
  ) async {
    final store = MemoryReminderSoundStore();
    final preview = _FakePreview();
    await pumpPage(tester, store, preview);

    await tester.tap(find.byKey(const Key('reminder-sound-marimba')));
    await tester.pump(const Duration(milliseconds: 1600));

    expect(await store.read(), ReminderSound.marimba);
    expect(preview.played, ['alera_reminder_marimba']);
  });

  testWidgets('vibrate only and silent can be selected without playing audio', (
    tester,
  ) async {
    final store = MemoryReminderSoundStore();
    final preview = _FakePreview();
    await pumpPage(tester, store, preview);

    await tester.tap(find.byKey(const Key('reminder-sound-vibrate')));
    await tester.pump();
    expect(await store.read(), ReminderSound.vibrateOnly);

    await tester.tap(find.byKey(const Key('reminder-sound-silent')));
    await tester.pump();
    expect(await store.read(), ReminderSound.silent);

    expect(preview.played, isEmpty);
  });

  testWidgets('preview button plays without changing the selection', (
    tester,
  ) async {
    final store = MemoryReminderSoundStore(ReminderSound.chime);
    final preview = _FakePreview();
    await pumpPage(tester, store, preview);

    await tester.tap(find.byTooltip('Preview Pulse'));
    await tester.pump(const Duration(milliseconds: 1600));

    expect(preview.played, ['alera_reminder_pulse']);
    expect(await store.read(), ReminderSound.chime);
  });

  testWidgets('fixed alert sounds can be previewed but not selected', (
    tester,
  ) async {
    final store = MemoryReminderSoundStore(ReminderSound.chime);
    final preview = _FakePreview();
    await pumpPage(tester, store, preview);

    await tester.tap(find.byKey(const Key('alert-sound-criticalAlert')));
    await tester.pump(const Duration(milliseconds: 1600));

    expect(preview.played, ['alera_alert_critical']);
    expect(await store.read(), ReminderSound.chime);
    expect(find.text('Critical alerts'), findsWidgets);
  });

  testWidgets('urgent alerts link to their system channel settings', (
    tester,
  ) async {
    final store = MemoryReminderSoundStore(ReminderSound.chime);
    final preview = _FakePreview();
    await pumpPage(tester, store, preview);

    await tester.ensureVisible(find.byKey(const Key('dnd-criticalAlert')));
    await tester.tap(find.byKey(const Key('dnd-criticalAlert')));
    await tester.pump();

    expect(preview.opened, ['alera_alert_critical_v1']);
    expect(preview.played, isEmpty);
  });
}
