import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_spacing.dart';
import '../../../design_system/alera_typography.dart';
import '../../../design_system/widgets/alera_card.dart';
import '../../../services/notification_sounds/notification_sound_catalog.dart';
import '../../../services/notification_sounds/notification_sound_preview.dart';
import '../../../services/notification_sounds/reminder_sound_store.dart';

/// Lets the user choose how ordinary reminders sound on this phone.
///
/// Alert sounds (warning, critical, help request, device status, missed
/// reminder) are fixed and listed here for reference only.
class ReminderSoundPage extends StatefulWidget {
  const ReminderSoundPage({super.key, this.store, this.preview});

  final ReminderSoundStore? store;
  final NotificationSoundPreview? preview;

  @override
  State<ReminderSoundPage> createState() => _ReminderSoundPageState();
}

class _ReminderSoundPageState extends State<ReminderSoundPage> {
  late final ReminderSoundStore _store = widget.store ?? reminderSoundStore;
  late final NotificationSoundPreview _preview =
      widget.preview ?? const PlatformNotificationSoundPreview();

  ReminderSound? _selected;
  String? _playing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _preview.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final ReminderSound sound = await _store.read();
    if (mounted) setState(() => _selected = sound);
  }

  Future<void> _select(ReminderSound sound) async {
    setState(() => _selected = sound);
    await _store.write(sound);
    await _play(sound.id, sound.rawResource, vibrates: sound.vibrates);
  }

  Future<void> _play(
    String key,
    String? resource, {
    bool vibrates = false,
  }) async {
    await _preview.stop();
    if (resource == null) {
      if (vibrates) await HapticFeedback.heavyImpact();
      if (mounted) setState(() => _playing = null);
      return;
    }
    if (mounted) setState(() => _playing = key);
    final bool played = await _preview.playResource(resource);
    if (!played && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't play the preview. Fully restart the app (not hot "
            'reload) and check your phone volume.',
          ),
        ),
      );
    }
    // Previews are short; clear the "playing" state shortly after.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted && _playing == key) setState(() => _playing = null);
  }

  Future<void> _openDndSettings(AlertSoundCategory category) async {
    final bool opened = await _preview.openChannelSettings(category.channelId);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open Settings > Apps > Alera > Notifications to change this.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ReminderSound? selected = _selected;

    return Scaffold(
      backgroundColor: AleraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Reminder sound'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AleraSpacing.large),
        children: [
          Text(
            'Choose how reminders sound on this phone. Tap a sound to hear it.',
            style: AleraTypography.body,
          ),
          const SizedBox(height: AleraSpacing.medium),
          AleraCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (int i = 0; i < ReminderSound.values.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 72),
                  _SoundRow(
                    key: Key('reminder-sound-${ReminderSound.values[i].id}'),
                    icon: _iconFor(ReminderSound.values[i]),
                    title: ReminderSound.values[i].label,
                    subtitle: ReminderSound.values[i].description,
                    selected: selected == ReminderSound.values[i],
                    playing: _playing == ReminderSound.values[i].id,
                    onTap: () => _select(ReminderSound.values[i]),
                    onPreview: ReminderSound.values[i].playsSound
                        ? () => _play(
                            ReminderSound.values[i].id,
                            ReminderSound.values[i].rawResource,
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AleraSpacing.large),
          Text('Alert sounds', style: AleraTypography.sectionTitle),
          const SizedBox(height: 4),
          Text(
            'These stay the same so urgent alerts are always recognisable. '
            'They can’t be changed here.',
            style: AleraTypography.body,
          ),
          const SizedBox(height: AleraSpacing.medium),
          AleraCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (int i = 0; i < AlertSoundCategory.values.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 72),
                  _SoundRow(
                    key: Key('alert-sound-${AlertSoundCategory.values[i].name}'),
                    icon: _alertIcon(AlertSoundCategory.values[i]),
                    title: AlertSoundCategory.values[i].channelName,
                    subtitle: AlertSoundCategory.values[i].description,
                    selected: false,
                    showSelection: false,
                    playing:
                        _playing == AlertSoundCategory.values[i].channelId,
                    onTap: () => _play(
                      AlertSoundCategory.values[i].channelId,
                      AlertSoundCategory.values[i].rawResource,
                    ),
                    onPreview: () => _play(
                      AlertSoundCategory.values[i].channelId,
                      AlertSoundCategory.values[i].rawResource,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AleraSpacing.large),
          Text('Do Not Disturb', style: AleraTypography.sectionTitle),
          const SizedBox(height: 4),
          Text(
            'Android only lets you decide this. Open an alert below and turn '
            'on “Override Do Not Disturb” so it still makes sound.',
            style: AleraTypography.body,
          ),
          const SizedBox(height: AleraSpacing.medium),
          AleraCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final (int i, AlertSoundCategory c) in <AlertSoundCategory>[
                  AlertSoundCategory.criticalAlert,
                  AlertSoundCategory.helpRequest,
                  AlertSoundCategory.missedReminder,
                ].indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 72),
                  ListTile(
                    key: Key('dnd-${c.name}'),
                    leading: Icon(
                      _alertIcon(c),
                      color: AleraColors.primaryMid,
                    ),
                    title: Text(c.channelName),
                    subtitle: const Text('Let through Do Not Disturb'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openDndSettings(c),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AleraSpacing.large),
          Text(
            'Android also lets you change a notification’s sound in the '
            'phone’s system settings, and those choices take priority over '
            'this screen.',
            style: AleraTypography.label,
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(ReminderSound sound) => switch (sound) {
    ReminderSound.vibrateOnly => Icons.vibration,
    ReminderSound.silent => Icons.notifications_off,
    _ => Icons.music_note,
  };

  static IconData _alertIcon(AlertSoundCategory category) => switch (category) {
    AlertSoundCategory.warningAlert => Icons.warning,
    AlertSoundCategory.criticalAlert => Icons.error,
    AlertSoundCategory.helpRequest => Icons.support_agent,
    AlertSoundCategory.deviceStatus => Icons.watch,
    AlertSoundCategory.missedReminder => Icons.alarm_off,
  };
}

class _SoundRow extends StatelessWidget {
  const _SoundRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.playing,
    required this.onTap,
    required this.onPreview,
    this.showSelection = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool playing;
  final bool showSelection;
  final VoidCallback onTap;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AleraColors.primaryMid
                    : AleraColors.primarySoft,
                borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? Colors.white : AleraColors.primaryMid,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AleraTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AleraColors.textPrimary,
                    ),
                  ),
                  Text(subtitle, style: AleraTypography.label),
                ],
              ),
            ),
            if (onPreview != null)
              IconButton(
                tooltip: 'Preview $title',
                onPressed: onPreview,
                icon: Icon(
                  playing ? Icons.volume_up : Icons.play_circle_filled,
                  color: AleraColors.primaryMid,
                  size: 30,
                ),
              ),
            if (showSelection)
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AleraColors.primaryMid : AleraColors.divider,
                size: 26,
              ),
          ],
        ),
      ),
    );
  }
}
