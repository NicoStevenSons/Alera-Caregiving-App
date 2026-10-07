import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../models/device_status_data.dart';
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
      // Deliberately at the very end of the page, away from the main
      // content, so it can't be hit by accident.
      footer: onSignOut == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 24),
              child: TextButton.icon(
                key: const Key('elderly-sign-out'),
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
                style: TextButton.styleFrom(
                  foregroundColor: AleraColors.textSecondary,
                ),
              ),
            ),
    );
  }
}
