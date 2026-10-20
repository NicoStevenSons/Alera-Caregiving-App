import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_text_field.dart';
import '../../../domain/philippine_mobile.dart';

/// The explanation shown wherever the backup contact is entered.
const String kBackupCaregiverExplanation =
    'This contact receives SMS escalation for critical alerts.';

/// Name and Philippine mobile number of the SMS-only backup caregiver.
///
/// The backup contact has no Alera account: it is just two optional fields.
/// Leave both empty for none; fill in one and the other becomes required.
/// Validation runs through the surrounding `Form`.
class BackupCaregiverFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool enabled;

  /// Offers "Remove backup caregiver" whenever both fields are filled.
  final VoidCallback? onRemove;

  const BackupCaregiverFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    this.enabled = true,
    this.onRemove,
  });

  bool _filled(TextEditingController c) => c.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Backup caregiver', style: AleraTypography.sectionTitle),
        const SizedBox(height: 4),
        const Text(
          kBackupCaregiverExplanation,
          key: Key('backup-explanation'),
          style: AleraTypography.caption,
        ),
        const SizedBox(height: 12),
        AleraTextField(
          controller: nameController,
          label: 'Backup caregiver name',
          hint: 'Enter backup caregiver’s full name',
          fieldKey: const Key('backup-name-field'),
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              validateBackupName(v, phoneEntered: _filled(phoneController)),
        ),
        AleraTextField(
          controller: phoneController,
          label: 'Backup caregiver mobile number',
          hint: '09XX XXX XXXX',
          fieldKey: const Key('backup-phone-field'),
          enabled: enabled,
          keyboardType: TextInputType.phone,
          validator: (v) =>
              validateBackupPhone(v, nameEntered: _filled(nameController)),
        ),
        if (onRemove != null)
          ListenableBuilder(
            listenable: Listenable.merge([nameController, phoneController]),
            builder: (context, _) =>
                _filled(nameController) && _filled(phoneController)
                ? Center(
                    child: TextButton.icon(
                      key: const Key('backup-remove'),
                      onPressed: enabled ? onRemove : null,
                      style: TextButton.styleFrom(
                        foregroundColor: AleraColors.critical,
                      ),
                      icon: const Icon(Icons.person_remove, size: 20),
                      label: const Text(
                        'Remove backup caregiver',
                        style: AleraTypography.bodyStrong,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
