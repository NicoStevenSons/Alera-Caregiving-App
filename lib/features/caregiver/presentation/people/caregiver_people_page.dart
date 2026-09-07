import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_spacing.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../domain/models/care_recipient.dart';
import '../../data/patients/caregiver_patient_controller.dart';
import 'widgets/care_recipient_card.dart';
import '../widgets/caregiver_page_app_bar.dart';

class CaregiverPeoplePage extends StatelessWidget {
  final List<CareRecipient> careRecipients;
  final ValueChanged<CareRecipient> onCareRecipientSelected;
  final VoidCallback? onAddPatient;
  final CaregiverPatientController? controller;

  const CaregiverPeoplePage({
    super.key,
    required this.careRecipients,
    required this.onCareRecipientSelected,
    this.onAddPatient,
    this.controller,
  });

  void _showMockFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) =>
            _buildPage(context, controller!.visiblePatients),
      );
    }
    return _buildPage(context, careRecipients);
  }

  Widget _buildPage(BuildContext context, List<CareRecipient> recipients) {
    return Scaffold(
      appBar: CaregiverPageAppBar(
        title: 'People',
        actions: [
          caregiverPageAction(
            tooltip: 'Filter people',
            onPressed: () => _showMockFeedback(
              context,
              'People filters are not available in the mock yet.',
            ),
            icon: Icons.filter_list,
          ),
          caregiverPageAction(
            tooltip: 'Edit people',
            onPressed: () => _showMockFeedback(
              context,
              'Editing people is not available in the mock yet.',
            ),
            icon: Icons.edit,
          ),
        ],
      ),
      body: _buildBody(context, recipients),
    );
  }

  Widget _buildBody(BuildContext context, List<CareRecipient> recipients) {
    final patientController = controller;
    if (patientController?.state == CaregiverPatientListState.initialLoading) {
      return const Center(
        key: Key('people-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (patientController?.state == CaregiverPatientListState.error) {
      return _PeopleMessage(
        key: const Key('people-error'),
        icon: Icons.cloud_off,
        title: patientController!.errorMessage ?? 'Unable to load patients.',
        actionLabel: 'Retry',
        onAction: patientController.load,
      );
    }
    if (patientController?.state == CaregiverPatientListState.empty) {
      return _PeopleMessage(
        key: const Key('people-empty'),
        icon: Icons.people_outline,
        title: 'No patients yet',
        actionLabel: 'Add Patient',
        onAction: onAddPatient,
      );
    }
    return RefreshIndicator(
      onRefresh: patientController == null
          ? () async {}
          : () => patientController.load(refresh: true),
      child: ListView.separated(
        key: const PageStorageKey<String>('caregiver-people-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AleraSpacing.medium,
          12,
          AleraSpacing.medium,
          AleraSpacing.medium,
        ),
        itemCount:
            recipients.length +
            1 +
            (patientController?.state == CaregiverPatientListState.demoFallback
                ? 1
                : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (patientController?.state ==
                  CaregiverPatientListState.demoFallback &&
              index == 0) {
            return const _DemoBanner();
          }
          final patientIndex =
              index -
              (patientController?.state ==
                      CaregiverPatientListState.demoFallback
                  ? 1
                  : 0);
          if (patientIndex < recipients.length) {
            final CareRecipient recipient = recipients[patientIndex];
            return CareRecipientCard(
              careRecipient: recipient,
              onTap: () => onCareRecipientSelected(recipient),
            );
          }

          return _AddPatientButton(
            onPressed:
                onAddPatient ??
                () => _showMockFeedback(
                  context,
                  'Adding a patient is not available in the mock yet.',
                ),
          );
        },
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();
  @override
  Widget build(BuildContext context) => Container(
    key: const Key('people-demo-fallback'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AleraColors.warning.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text('Demo data — the patient service is currently offline.'),
  );
}

class _PeopleMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback? onAction;
  const _PeopleMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.actionLabel,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AleraColors.textSecondary),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

class _AddPatientButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddPatientButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: EdgeInsets.zero,
      onTap: onPressed,
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 24, color: AleraColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Add Patient',
              style: AleraTypography.label.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
