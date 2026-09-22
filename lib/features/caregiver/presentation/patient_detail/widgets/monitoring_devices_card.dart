import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/health_snapshot.dart';

class PatientMonitoringDevicesCard extends StatelessWidget {
  final List<MonitoringDevice> devices;

  const PatientMonitoringDevicesCard({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monitoring Devices', style: AleraTypography.sectionTitle),
          const SizedBox(height: 6),
          _DeviceRow(
            name: 'Watch',
            assetPath:
                'alera-figma-assets/assets/icons/devices/watch-monitoring.svg',
            device: devices.watch,
          ),
          Divider(
            height: 8,
            thickness: 1,
            color: AleraColors.divider.withValues(alpha: 0.30),
          ),
          _DeviceRow(
            name: 'Phone',
            assetPath:
                'alera-figma-assets/assets/icons/devices/phone-monitoring.svg',
            device: devices.phone,
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final String name;
  final String assetPath;
  final MonitoringDevice? device;

  const _DeviceRow({
    required this.name,
    required this.assetPath,
    required this.device,
  });

  String get _statusLabel {
  if (device == null) return 'Unavailable';

  final isWatch = name.toLowerCase() == 'watch';

  switch (device!.connectionStatus) {
    case MonitoringDeviceConnectionStatus.disconnected:
      return 'Disconnected';

    case MonitoringDeviceConnectionStatus.unknown:
      return 'Unknown';

    case MonitoringDeviceConnectionStatus.connected:
      if (!isWatch) {
        return 'Connected';
      }

      if (device!.isWorn == false) {
        return 'Not worn';
      }

      if (device!.isWorn == true) {
        return 'Connected • On wrist';
      }

      return 'Connected';
  }
}

  Color get _statusColor {
  if (device == null) {
    return AleraColors.textSecondary;
  }

  final isWatch = name.toLowerCase() == 'watch';

  switch (device!.connectionStatus) {
    case MonitoringDeviceConnectionStatus.disconnected:
      return AleraColors.critical;

    case MonitoringDeviceConnectionStatus.unknown:
      return AleraColors.textSecondary;

    case MonitoringDeviceConnectionStatus.connected:
      if (isWatch && device!.isWorn == false) {
        return AleraColors.warning;
      }

      return AleraColors.success;
  }
}

  String get _batteryLabel {
    final battery = device?.batteryPercent;

    if (device == null) return 'Unavailable';
    if (battery == null) return '--';

    return '$battery%';
  }

  @override
  Widget build(BuildContext context) {
    final available = device != null;

    return Row(
      children: [
        AleraSvgIcon(
          assetPath: assetPath,
          width: 24,
          height: 24,
          semanticLabel: name,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AleraTypography.body.copyWith(fontSize: 13)),
              Row(
                children: [
                  if (available) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _statusLabel,
                    style: AleraTypography.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(_batteryLabel, style: AleraTypography.label),
        const SizedBox(width: 7),
        Icon(
          Icons.battery_5_bar,
          color: device?.batteryPercent != null
              ? AleraColors.primary
              : AleraColors.textSecondary,
          size: 20,
        ),
      ],
    );
  }
}
