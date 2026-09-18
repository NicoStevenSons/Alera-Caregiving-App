import 'package:flutter/material.dart';

import '../../../../models/device_status_data.dart';

class DeviceStatusTab extends StatelessWidget {
  final DeviceStatusData deviceStatusData;

  const DeviceStatusTab({
    super.key,
    required this.deviceStatusData,
  });

  @override
  Widget build(BuildContext context) {
    final bool? connected = deviceStatusData.connectedToPhone;
    final bool? charging = deviceStatusData.isCharging;
    final int? battery = deviceStatusData.batteryPercent;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DeviceHeroCard(
            data: deviceStatusData,
            connected: connected,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatusTile(
                  icon: charging == true
                      ? Icons.battery_charging_full_rounded
                      : Icons.battery_std_rounded,
                  label: 'Battery',
                  value: deviceStatusData.displayedBattery,
                  supportingText: deviceStatusData.displayedCharging,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusTile(
                  icon: connected == true
                      ? Icons.link_rounded
                      : Icons.link_off_rounded,
                  label: 'Connection',
                  value: deviceStatusData.displayedConnection,
                  supportingText: connected == true
                      ? 'Watch link is active'
                      : 'Waiting for watch',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BatteryCard(
            battery: battery,
            isCharging: charging,
          ),
          const SizedBox(height: 16),
          _DetailsCard(data: deviceStatusData),
          const SizedBox(height: 16),
          _LastUpdateCard(measuredAt: deviceStatusData.measuredAt),
        ],
      ),
    );
  }
}

class _DeviceHeroCard extends StatelessWidget {
  final DeviceStatusData data;
  final bool? connected;

  const _DeviceHeroCard({
    required this.data,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = connected == true
        ? Colors.green
        : connected == false
            ? Colors.redAccent
            : Colors.grey;

    return Card(
      elevation: 0,
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                connected == false
                    ? Icons.watch_off_rounded
                    : Icons.watch_rounded,
                size: 38,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.displayedDeviceName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.deviceModel ?? 'Smartwatch',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        data.displayedConnection,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String supportingText;

  const _StatusTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.supportingText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.purple.shade600),
            const SizedBox(height: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              supportingText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  final int? battery;
  final bool? isCharging;

  const _BatteryCard({
    required this.battery,
    required this.isCharging,
  });

  @override
  Widget build(BuildContext context) {
    final double? progress =
        battery == null ? null : battery!.clamp(0, 100).toDouble() / 100;

    String message;
    if (isCharging == true) {
      message = 'Your watch is currently charging.';
    } else if (battery == null) {
      message = 'Battery information has not arrived from the watch yet.';
    } else if (battery! <= 20) {
      message = 'Battery is low. Charge the watch soon to keep monitoring active.';
    } else {
      message = 'Battery level is healthy for continued monitoring.';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCharging == true
                      ? Icons.bolt_rounded
                      : Icons.battery_5_bar_rounded,
                  color: Colors.purple.shade600,
                ),
                const SizedBox(width: 10),
                Text(
                  'Watch battery',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  battery == null ? '--' : '$battery%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final DeviceStatusData data;

  const _DetailsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.watch_rounded,
              label: 'Device',
              value: data.displayedDeviceName,
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.memory_rounded,
              label: 'Model',
              value: data.deviceModel ?? '--',
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.smartphone_rounded,
              label: 'Paired phone',
              value: data.displayedPhoneName,
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: data.isCharging == true
                  ? Icons.battery_charging_full_rounded
                  : Icons.power_rounded,
              label: 'Power',
              value: data.displayedCharging,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: Colors.purple.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _LastUpdateCard extends StatelessWidget {
  final String? measuredAt;

  const _LastUpdateCard({required this.measuredAt});

  String _formatLastUpdate() {
    if (measuredAt == null || measuredAt!.isEmpty) {
      return 'No device update received yet';
    }

    final DateTime? parsed = DateTime.tryParse(measuredAt!);
    if (parsed == null) {
      return measuredAt!;
    }

    final DateTime local = parsed.toLocal();
    final String month = local.month.toString().padLeft(2, '0');
    final String day = local.day.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');

    return '${local.year}-$month-$day  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 20, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Last device update: ${_formatLastUpdate()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
