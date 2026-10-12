import 'package:flutter/material.dart';

import '../../../../design_system/widgets/alera_dialog.dart';
import '../../../../models/device_status_data.dart';

Future<void> showDeviceStatusDialog({
  required BuildContext context,
  required DeviceStatusData deviceStatusData,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AleraDialog(
        icon: Icons.watch,
        title: 'Device Status',
        showCancel: false,
        confirmLabel: 'Close',
        onConfirm: () => Navigator.of(dialogContext).pop(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device: ${deviceStatusData.displayedDeviceName}'),
            const SizedBox(height: 8),
            Text('Model: ${deviceStatusData.deviceModel ?? '--'}'),
            const SizedBox(height: 8),
            Text('Battery: ${deviceStatusData.displayedBattery}'),
            const SizedBox(height: 8),
            Text('Connection: ${deviceStatusData.displayedConnection}'),
            const SizedBox(height: 8),
            Text('Phone: ${deviceStatusData.displayedPhoneName}'),
          ],
        ),
      );
    },
  );
}
