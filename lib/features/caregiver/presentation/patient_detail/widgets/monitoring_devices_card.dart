import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/health_snapshot.dart';

/// Watch and phone on two compact rows: connection chip and battery.
class PatientMonitoringDevicesCard extends StatelessWidget {
  final List<MonitoringDevice> devices;

  const PatientMonitoringDevicesCard({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Devices', style: AleraTypography.sectionTitle),
          const SizedBox(height: 8),
          _DeviceRow(
            name: 'Watch',
            assetPath:
                'alera-figma-assets/assets/icons/devices/watch-monitoring.svg',
            device: devices.watch,
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: AleraColors.divider,
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

  bool get _isWatch => name.toLowerCase() == 'watch';

  String get _statusLabel {
    final d = device;
    if (d == null) return 'Unavailable';
    switch (d.connectionStatus) {
      case MonitoringDeviceConnectionStatus.disconnected:
        return 'Disconnected';
      case MonitoringDeviceConnectionStatus.unknown:
        return 'Unknown';
      case MonitoringDeviceConnectionStatus.connected:
        if (!_isWatch) return 'Connected';
        if (d.isWorn == false) return 'Not worn';
        if (d.isWorn == true) return 'On wrist';
        return 'Connected';
    }
  }

  Color get _statusColor {
    final d = device;
    if (d == null) return AleraColors.textSecondary;
    switch (d.connectionStatus) {
      case MonitoringDeviceConnectionStatus.disconnected:
        return AleraColors.critical;
      case MonitoringDeviceConnectionStatus.unknown:
        return AleraColors.textSecondary;
      case MonitoringDeviceConnectionStatus.connected:
        return _isWatch && d.isWorn == false
            ? const Color(0xFFD99A00)
            : const Color(0xFF05A869);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? battery = device?.batteryPercent;
    final Color status = _statusColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          AleraSvgIcon(
            assetPath: assetPath,
            width: 28,
            height: 28,
            semanticLabel: name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: AleraTypography.label.copyWith(
                color: AleraColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: status,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 74,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  device == null ? '--' : (battery == null ? '--' : '$battery%'),
                  style: AleraTypography.label.copyWith(fontSize: 13),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.battery_5_bar,
                  size: 20,
                  color: battery == null
                      ? AleraColors.mutedIcon
                      : AleraColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
