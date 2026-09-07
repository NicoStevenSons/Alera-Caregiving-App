import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/widgets/alera_button.dart';
import '../../../domain/models/care_recipient.dart';

class HomePatientHeader extends StatelessWidget {
  final CareRecipient careRecipient;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  const HomePatientHeader({
    super.key,
    required this.careRecipient,
    required this.onCall,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFC3A7F5), // Top: Medium Soft Lavender
            Color(0xFFE8E0FF), // Bottom: Light Pale Lavender
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Column(
          children: [
            Row(
              children: [
                _InitialAvatar(name: careRecipient.name),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        careRecipient.name,
                        style: const TextStyle(
                          color: AleraColors.textPrimary,
                          fontSize: 20,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 15,
                            color: AleraColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            careRecipient.healthSnapshot.hasLastCheckIn
                                ? 'Last Check-in: ${_time(careRecipient.healthSnapshot.lastCheckIn)}'
                                : 'Last Check-in: No data',
                            style: const TextStyle(
                              color: AleraColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AleraButton(
                    label: 'Call',
                    icon: Icons.phone,
                    onPressed: onCall,
                    variant: AleraButtonVariant.primary,
                    expand: true,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AleraButton(
                    label: 'Message',
                    icon: Icons.message,
                    onPressed: onMessage,
                    variant: AleraButtonVariant.primary,
                    expand: true,
                    height: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime value) {
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;

    return '$hour:${value.minute.toString().padLeft(2, '0')} '
        '${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;

  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final String initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();

    final int seed = name.codeUnits.fold(0, (sum, value) => sum + value);

    const List<Color> colors = [
      Color(0xFF8165C7),
      Color(0xFF4D91A8),
      Color(0xFFB36B8D),
    ];

    return CircleAvatar(
      radius: 25,
      backgroundColor: colors[seed % colors.length],
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
