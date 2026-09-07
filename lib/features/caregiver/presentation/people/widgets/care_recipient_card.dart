import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_spacing.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/care_recipient.dart';

class CareRecipientCard extends StatelessWidget {
  final CareRecipient careRecipient;
  final VoidCallback onTap;

  const CareRecipientCard({
    super.key,
    required this.careRecipient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isStable = careRecipient.status == CareStatus.stable;

    return AleraCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InitialAvatar(name: careRecipient.name),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  careRecipient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AleraTypography.sectionTitle.copyWith(
                    fontSize: 18,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 2),
                if (careRecipient.addressOrRoom != null) ...[
                  Text(
                    careRecipient.addressOrRoom!,
                    style: AleraTypography.body.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                ],
                _StatusRow(
                  assetPath: isStable
                      ? 'alera-figma-assets/assets/icons/status/stable.svg'
                      : 'alera-figma-assets/assets/icons/status/warning.svg',
                  label: careRecipient.backendBacked
                      ? careRecipient.monitoringStatusLabel
                      : isStable
                      ? 'Stable'
                      : 'High Heart Rate',
                ),
                const SizedBox(height: 2),
                _StatusRow(
                  assetPath:
                      'alera-figma-assets/assets/icons/status/alert.svg',
                  label: careRecipient.alertCount == 0
                      ? 'No Alerts'
                      : '${careRecipient.alertCount} Alerts',
                ),
                const SizedBox(height: 2),
                _StatusRow(
                  assetPath:
                      'alera-figma-assets/assets/icons/status/reminder.svg',
                  label: '${careRecipient.reminderCount} Reminders',
                ),
                const SizedBox(height: 4),
                const Wrap(
                  spacing: 14,
                  runSpacing: 2,
                  children: [
                    _DeviceAvailability(
                      assetPath:
                          'alera-figma-assets/assets/icons/devices/phone-monitoring.svg',
                    ),
                    _DeviceAvailability(
                      assetPath:
                          'alera-figma-assets/assets/icons/devices/watch-monitoring.svg',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Icon(
              Icons.chevron_right,
              color: Color(0xFFB7B2C3),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;

  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final List<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    final String initials = words
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();

    const List<Color> colors = [
      AleraColors.primary,
      AleraColors.information,
      AleraColors.critical,
    ];

    final int colorIndex =
        name.codeUnits.fold(0, (sum, value) => sum + value) % colors.length;

    return CircleAvatar(
      radius: 20,
      backgroundColor: colors[colorIndex],
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String assetPath;
  final String label;

  const _StatusRow({
    required this.assetPath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AleraSvgIcon(assetPath: assetPath, width: 16, height: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AleraTypography.body.copyWith(
              fontSize: 13,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DeviceAvailability extends StatelessWidget {
  final String assetPath;

  const _DeviceAvailability({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AleraSvgIcon(
          assetPath: assetPath,
          width: 17,
          height: 17,
        ),
        const SizedBox(width: AleraSpacing.xSmall),
        Text(
          'Unavailable',
          style: AleraTypography.body.copyWith(
            fontSize: 14,
            height: 1,
          ),
        ),
      ],
    );
  }
}