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
            device: _findDevice('watch'),
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
            device: _findDevice('phone'),
          ),
        ],
      ),
    );
  }

  MonitoringDevice? _findDevice(String expectedName) {
    for (final MonitoringDevice device in devices) {
      if (device.name.toLowerCase() == expectedName) return device;
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    final bool available = device != null;
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
                        color: device!.isConnected
                            ? AleraColors.success
                            : AleraColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    available
                        ? device!.isConnected
                              ? 'Connected'
                              : 'Disconnected'
                        : 'Unavailable',
                    style: AleraTypography.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          available ? '${device!.batteryPercent}%' : 'Unavailable',
          style: AleraTypography.label,
        ),
        const SizedBox(width: 7),
        Icon(
          Icons.battery_5_bar,
          color: available ? AleraColors.primary : AleraColors.textSecondary,
          size: 20,
        ),
      ],
    );
  }
}
