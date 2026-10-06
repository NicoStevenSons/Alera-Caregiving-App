import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_patient_avatar.dart';
import '../../../domain/models/care_recipient.dart';

/// Who the patient is, plus the four things a caregiver does most: call,
/// message, add a reminder, add a note.
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              AleraPatientAvatar(
                name: careRecipient.name,
                photoUrl: careRecipient.profilePhotoUrl,
                radius: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      careRecipient.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AleraTypography.sectionTitle.copyWith(
                        fontSize: 20,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AleraColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          careRecipient.relationshipLabel,
                          style: const TextStyle(
                            color: AleraColors.primary,
                            fontSize: 11,
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
          const SizedBox(height: 16),
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
                label: 'Add note',
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AleraColors.primarySoft.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: AleraColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AleraColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
