import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../domain/models/care_recipient.dart';

class PatientDetailSummaryCard extends StatelessWidget {
  final CareRecipient careRecipient;
  final ValueChanged<String> onAction;

  const PatientDetailSummaryCard({
    super.key,
    required this.careRecipient,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
                      style: AleraTypography.sectionTitle.copyWith(
                        fontSize: 19,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AleraColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          careRecipient.relationshipLabel,
                          style: const TextStyle(
                            color: AleraColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _QuickAction(
                icon: Icons.phone,
                label: 'Call',
                onTap: () => onAction('Call'),
              ),
              _QuickAction(
                icon: Icons.message,
                label: 'Message',
                onTap: () => onAction('Message'),
              ),
              _QuickAction(
                icon: Icons.notifications_active,
                label: 'Reminder',
                onTap: () => onAction('Reminder'),
              ),
              _QuickAction(
                icon: Icons.edit,
                label: 'Add Note',
                onTap: () => onAction('Add Note'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: AleraColors.textSecondary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AleraColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;

  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final List<String> words = name.trim().split(RegExp(r'\s+'));
    final String initials = words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    final int colorSeed = name.codeUnits.fold(0, (sum, value) => sum + value);
    const List<Color> colors = [
      Color(0xFF8165C7),
      Color(0xFF4D91A8),
      Color(0xFFB36B8D),
    ];

    return CircleAvatar(
      radius: 24,
      backgroundColor: colors[colorSeed % colors.length],
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
