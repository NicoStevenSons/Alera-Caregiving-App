import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_spacing.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_dialog.dart';
import '../../../../design_system/widgets/alera_snackbar.dart';
import '../../../notifications/presentation/reminder_sound_page.dart';
import '../../data/api/caregiver_help_request_api_data_source.dart';
import '../help_requests/caregiver_help_request_history_page.dart';
import '../widgets/caregiver_page_app_bar.dart';

/// "More" tab: shortcuts for people, help requests, app settings and sign
/// out. Rows without a destination yet are tagged "Soon".
class CaregiverMorePage extends StatelessWidget {
  const CaregiverMorePage({
    super.key,
    required this.helpRequestDataSource,
    required this.onManagePatients,
    required this.onAddPatient,
    this.onSignOut,
  });

  final CaregiverHelpRequestDataSource? helpRequestDataSource;
  final VoidCallback onManagePatients;
  final VoidCallback onAddPatient;
  final VoidCallback? onSignOut;

  void _soon(BuildContext context, String label) {
    showAleraSnackBar(
      context,
      '$label is coming soon.',
      type: AleraSnackBarType.info,
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool confirmed = await showAleraConfirmDialog(
      context,
      icon: Icons.logout,
      title: 'Sign out?',
      message: 'You will need to sign in again to see your patients.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (confirmed) onSignOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    final source = helpRequestDataSource;
    final CaregiverHelpRequestNotesDataSource? notesSource =
        source is CaregiverHelpRequestNotesDataSource
        ? source as CaregiverHelpRequestNotesDataSource
        : null;

    return Scaffold(
      appBar: const CaregiverPageAppBar(title: 'More'),
      body: ListView(
        key: const PageStorageKey<String>('caregiver-more'),
        padding: const EdgeInsets.fromLTRB(
          AleraSpacing.medium,
          AleraSpacing.small,
          AleraSpacing.medium,
          AleraSpacing.medium,
        ),
        children: [
          const _GroupLabel('Care'),
          _GroupCard(
            children: [
              _MoreRow(
                icon: Icons.people,
                label: 'Manage patients',
                onTap: onManagePatients,
              ),
              _MoreRow(
                icon: Icons.person_add,
                label: 'Add a patient',
                onTap: onAddPatient,
              ),
              _MoreRow(
                key: const Key('more-help-request-history'),
                icon: Icons.support_agent,
                label: 'Help request history',
                onTap: source == null || notesSource == null
                    ? () => _soon(context, 'Help request history')
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CaregiverHelpRequestHistoryPage(
                            dataSource: source,
                            notesDataSource: notesSource,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _GroupLabel('App'),
          _GroupCard(
            children: [
              _MoreRow(
                key: const Key('more-reminder-sound'),
                icon: Icons.notifications_active,
                label: 'Reminder sound',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReminderSoundPage(),
                  ),
                ),
              ),
              _MoreRow(
                icon: Icons.settings,
                label: 'Notification settings',
                soon: true,
                onTap: () => _soon(context, 'Notification settings'),
              ),
              _MoreRow(
                icon: Icons.help,
                label: 'Help & support',
                soon: true,
                onTap: () => _soon(context, 'Help & support'),
              ),
              _MoreRow(
                icon: Icons.privacy_tip,
                label: 'Privacy & terms',
                soon: true,
                onTap: () => _soon(context, 'Privacy & terms'),
              ),
            ],
          ),
          if (onSignOut != null) ...[
            const SizedBox(height: 16),
            _GroupCard(
              children: [
                _MoreRow(
                  key: const Key('caregiver-sign-out'),
                  icon: Icons.logout,
                  label: 'Sign out',
                  color: AleraColors.critical,
                  chevron: false,
                  onTap: () => _confirmSignOut(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: AleraTypography.sectionTitle),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final List<Widget> spaced = [];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        spaced.add(
          const Divider(
            height: 1,
            indent: 60,
            endIndent: 14,
            color: AleraColors.divider,
          ),
        );
      }
      spaced.add(children[i]);
    }
    return AleraCard(
      padding: EdgeInsets.zero,
      child: Column(children: spaced),
    );
  }
}

class _MoreRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool soon;
  final bool chevron;
  final Color? color;

  const _MoreRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.soon = false,
    this.chevron = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = color ?? AleraColors.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color ?? AleraColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (soon)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AleraColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(
                    color: AleraColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (chevron)
              const Icon(
                Icons.chevron_right,
                color: AleraColors.mutedChevron,
              ),
          ],
        ),
      ),
    );
  }
}
