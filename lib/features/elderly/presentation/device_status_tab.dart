import 'package:flutter/material.dart';

import '../../../models/device_status_data.dart';
import '../../../design_system/alera_colors.dart';
import 'widgets/elderly_widgets.dart';

const Color _good = Color(0xFF05A869);
const Color _warn = Color(0xFFD99A00);
const Color _bad = Color(0xFFE04C5D);

class DeviceStatusTab extends StatelessWidget {
  final DeviceStatusData deviceStatusData;

  /// Optional content placed at the very end of the scrolling page.
  final Widget? footer;

  const DeviceStatusTab({
    super.key,
    required this.deviceStatusData,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final DeviceStatusData data = deviceStatusData;
    final bool? connected = data.connectedToPhone;
    final bool? charging = data.isCharging;
    final int? battery = data.batteryPercent;
    final bool? isWorn = data.isWorn;

    final Color connectionColor = connected == true
        ? _good
        : connected == false
        ? _bad
        : AleraColors.textSecondary;

    final Color batteryColor = charging == true
        ? _good
        : battery == null
        ? AleraColors.textSecondary
        : battery <= 20
        ? _bad
        : battery <= 40
        ? _warn
        : _good;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ElderlyIconTile(
                    icon: connected == false
                        ? Icons.watch_off_rounded
                        : Icons.watch_rounded,
                    color: connectionColor == AleraColors.textSecondary
                        ? AleraColors.primary
                        : connectionColor,
                    size: 64,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.displayedDeviceName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AleraColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ElderlyStatusChip(
                          label: data.displayedConnection,
                          color: connectionColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isWorn == false) ...[
            const SizedBox(height: 12),
            _Notice(
              icon: Icons.watch_off_rounded,
              color: _warn,
              title: 'Watch not worn',
              message:
                  'Put the watch back on to keep activity monitoring accurate.',
            ),
          ],
          const SizedBox(height: 24),
          const ElderlySectionTitle('Watch status'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _StatusRow(
                    icon: charging == true
                        ? Icons.battery_charging_full_rounded
                        : Icons.battery_std_rounded,
                    color: batteryColor,
                    label: 'Battery',
                    value: data.displayedBattery,
                    detail: data.displayedCharging,
                  ),
                  const Divider(height: 1, color: AleraColors.divider),
                  _StatusRow(
                    icon: connected == false
                        ? Icons.link_off_rounded
                        : Icons.link_rounded,
                    color: connectionColor == AleraColors.textSecondary
                        ? AleraColors.primary
                        : connectionColor,
                    label: 'Connection',
                    value: data.displayedConnection,
                    detail: connected == true
                        ? 'Watch link is active'
                        : 'Waiting for watch',
                  ),
                  const Divider(height: 1, color: AleraColors.divider),
                  _StatusRow(
                    icon: isWorn == false
                        ? Icons.watch_off_rounded
                        : Icons.watch_rounded,
                    color: isWorn == true
                        ? _good
                        : isWorn == false
                        ? _warn
                        : AleraColors.primary,
                    label: 'Wear status',
                    value: data.displayedWearStatus,
                    detail: isWorn == true
                        ? 'Watch is being worn'
                        : isWorn == false
                        ? 'Watch is off wrist'
                        : 'Waiting for wear status',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _BatteryCard(
            battery: battery,
            isCharging: charging,
            color: batteryColor,
          ),
          const SizedBox(height: 24),
          const ElderlySectionTitle('Device details'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.memory_rounded,
                    label: 'Model',
                    value: data.deviceModel ?? '--',
                  ),
                  const Divider(height: 1, color: AleraColors.divider),
                  _DetailRow(
                    icon: Icons.smartphone_rounded,
                    label: 'Paired phone',
                    value: data.displayedPhoneName,
                  ),
                  const Divider(height: 1, color: AleraColors.divider),
                  _DetailRow(
                    icon: Icons.access_time_filled,
                    label: 'Last update',
                    value: _formatLastUpdate(data.measuredAt),
                  ),
                ],
              ),
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }

  static String _formatLastUpdate(String? measuredAt) {
    if (measuredAt == null || measuredAt.isEmpty) return 'No update yet';
    final DateTime? parsed = DateTime.tryParse(measuredAt);
    if (parsed == null) return measuredAt;
    final DateTime local = parsed.toLocal();
    final int hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final String minute = local.minute.toString().padLeft(2, '0');
    final String period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}  $hour:$minute $period';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          ElderlyIconTile(icon: icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AleraColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AleraColors.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AleraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  const _BatteryCard({
    required this.battery,
    required this.isCharging,
    required this.color,
  });

  final int? battery;
  final bool? isCharging;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double? progress = battery == null
        ? null
        : battery!.clamp(0, 100).toDouble() / 100;

    final String message;
    if (isCharging == true) {
      message = 'Your watch is currently charging.';
    } else if (battery == null) {
      message = 'Battery information has not arrived from the watch yet.';
    } else if (battery! <= 20) {
      message =
          'Battery is low. Charge the watch soon to keep monitoring active.';
    } else {
      message = 'Battery level is healthy for continued monitoring.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Watch battery',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AleraColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  battery == null ? '--' : '$battery%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress ?? 0,
                minHeight: 14,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AleraColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 26, color: AleraColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                color: AleraColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AleraColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElderlyIconTile(icon: icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AleraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AleraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
