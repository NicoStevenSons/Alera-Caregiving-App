import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../models/device_status_data.dart';
import '../../notifications/presentation/reminder_sound_page.dart';
import 'device_status_tab.dart';

class ElderlyMorePage extends StatelessWidget {
  const ElderlyMorePage({
    super.key,
    required this.deviceStatusData,
    this.onSignOut,
  });

  final DeviceStatusData deviceStatusData;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return DeviceStatusTab(
      key: const PageStorageKey<String>('elderly-more'),
      deviceStatusData: deviceStatusData,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              key: const Key('elderly-reminder-sound'),
              leading: const Icon(Icons.notifications_active),
              title: const Text('Reminder sound'),
              subtitle: const Text('Choose how reminders sound'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReminderSoundPage(),
                ),
              ),
            ),
          ),
          if (onSignOut != null) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              key: const Key('elderly-sign-out'),
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
              style: TextButton.styleFrom(
                foregroundColor: AleraColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
