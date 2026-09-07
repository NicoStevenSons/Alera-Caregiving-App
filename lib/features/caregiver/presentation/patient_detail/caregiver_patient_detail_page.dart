import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_spacing.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../domain/models/care_recipient.dart';
import '../../domain/models/caregiver_alert.dart';
import '../../domain/models/caregiver_reminder.dart';
import '../../data/api/caregiver_patient_api_data_source.dart';
import '../../data/patients/caregiver_patient_controller.dart';
import 'widgets/care_status_card.dart';
import 'widgets/patient_alert_history.dart';
import 'widgets/patient_reminders_section.dart';
import 'widgets/monitoring_devices_card.dart';
import 'widgets/patient_summary_card.dart';
import 'widgets/patient_vital_summary_section.dart';

class CaregiverPatientDetailPage extends StatelessWidget {
  final CareRecipient careRecipient;
  final List<CaregiverAlert> alerts;
  final List<CaregiverReminder> reminders;
  final VoidCallback onViewAllAlerts;
  final VoidCallback onViewAllReminders;
  final ValueChanged<CaregiverAlert> onAlertTap;
  final ValueChanged<CaregiverAlert>? onMarkAsSeen;

  const CaregiverPatientDetailPage({
    super.key,
    required this.careRecipient,
    required this.alerts,
    required this.reminders,
    required this.onViewAllAlerts,
    required this.onViewAllReminders,
    required this.onAlertTap,
    this.onMarkAsSeen,
  });

  void _showMockFeedback(BuildContext context, String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$action is mock-only for now.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left, size: 28),
          color: const Color(0xFFB4AEC2),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: ValueKey('caregiver-patient-detail-${careRecipient.id}'),
          padding: const EdgeInsets.fromLTRB(
            AleraSpacing.medium,
            AleraSpacing.small,
            AleraSpacing.medium,
            AleraSpacing.medium,
          ),
          children: [
            PatientDetailSummaryCard(
              careRecipient: careRecipient,
              onAction: (action) => _showMockFeedback(context, action),
            ),
            const SizedBox(height: 12),
            _DashboardCounters(careRecipient: careRecipient),
            const SizedBox(height: 12),
            PatientCareStatusCard(careRecipient: careRecipient),
            const SizedBox(height: 12),
            PatientMonitoringDevicesCard(
              devices: careRecipient.healthSnapshot.devices,
            ),
            const SizedBox(height: 12),
            PatientAlertHistory(
              alerts: alerts,
              onViewAll: onViewAllAlerts,
              onAlertTap: onAlertTap,
              onMarkAsSeen: onMarkAsSeen,
            ),
            const SizedBox(height: 12),
            PatientVitalSummarySection(
              snapshot: careRecipient.healthSnapshot,
              onVitalTap: (label) =>
                  _showMockFeedback(context, '$label history'),
            ),
            const SizedBox(height: 12),
            PatientRemindersSection(
              reminders: reminders,
              onViewAll: onViewAllReminders,
              onAction: (action) => _showMockFeedback(context, action),
            ),
          ],
        ),
      ),
    );
  }
}

class CaregiverPatientDetailLoaderPage extends StatefulWidget {
  final String patientId;
  final CaregiverPatientController controller;
  final List<CaregiverAlert> alerts;
  final List<CaregiverReminder> reminders;
  final VoidCallback onViewAllAlerts;
  final VoidCallback onViewAllReminders;
  final ValueChanged<CaregiverAlert> onAlertTap;
  final ValueChanged<CaregiverAlert>? onMarkAsSeen;

  const CaregiverPatientDetailLoaderPage({
    super.key,
    required this.patientId,
    required this.controller,
    required this.alerts,
    required this.reminders,
    required this.onViewAllAlerts,
    required this.onViewAllReminders,
    required this.onAlertTap,
    this.onMarkAsSeen,
  });

  @override
  State<CaregiverPatientDetailLoaderPage> createState() =>
      _CaregiverPatientDetailLoaderPageState();
}

class _CaregiverPatientDetailLoaderPageState
    extends State<CaregiverPatientDetailLoaderPage> {
  CareRecipient? _patient;
  CaregiverPatientApiFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _patient = null;
      _failure = null;
    });
    try {
      final detail = await widget.controller.loadDetail(widget.patientId);
      if (mounted) {
        setState(() => _patient = patientDetailToCareRecipient(detail));
      }
    } on CaregiverPatientApiFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_patient != null) {
      return CaregiverPatientDetailPage(
        careRecipient: _patient!,
        alerts: widget.alerts,
        reminders: widget.reminders,
        onViewAllAlerts: widget.onViewAllAlerts,
        onViewAllReminders: widget.onViewAllReminders,
        onAlertTap: widget.onAlertTap,
        onMarkAsSeen: widget.onMarkAsSeen,
      );
    }
    final failure = _failure;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left, size: 28),
          color: const Color(0xFFB4AEC2),
        ),
      ),
      body: Center(
        child: failure == null
            ? const CircularProgressIndicator(
                key: Key('patient-detail-loading'),
              )
            : Column(
                key: Key(
                  failure.kind == CaregiverPatientFailureKind.notFound
                      ? 'patient-detail-not-found'
                      : 'patient-detail-error',
                ),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    failure.kind == CaregiverPatientFailureKind.notFound
                        ? Icons.person_off_outlined
                        : Icons.error_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    failure.kind == CaregiverPatientFailureKind.notFound
                        ? 'Patient not found.'
                        : failure.message,
                    textAlign: TextAlign.center,
                  ),
                  if (failure.kind !=
                          CaregiverPatientFailureKind.unauthorized &&
                      failure.kind !=
                          CaregiverPatientFailureKind.forbidden) ...[
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ],
              ),
      ),
    );
  }
}

class _DashboardCounters extends StatelessWidget {
  final CareRecipient careRecipient;

  const _DashboardCounters({required this.careRecipient});

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: _Counter(
              assetPath: 'alera-figma-assets/assets/icons/status/alert.svg',
              color: const Color(0xFFB48BF2),
              value: '${careRecipient.alertCount}',
              label: 'Alerts\nToday',
            ),
          ),
          _SummaryDivider(),
          Expanded(
            child: _Counter(
              assetPath: 'alera-figma-assets/assets/icons/status/reminder.svg',
              color: const Color(0xFF55A5FF),
              value: '${careRecipient.reminderCount}',
              label: 'Reminders\nToday',
            ),
          ),
          _SummaryDivider(),
          const Expanded(
            child: _Counter(
              assetPath:
                  'alera-figma-assets/assets/icons/mini_status/stable.svg',
              color: Color(0xFF08D887),
              value: '',
              label: 'Monitoring\nActive',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    color: AleraColors.divider.withValues(alpha: 0.55),
  );
}

class _Counter extends StatelessWidget {
  final String assetPath;
  final Color color;
  final String value;
  final String label;

  const _Counter({
    required this.assetPath,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AleraSvgIcon(
              assetPath: assetPath,
              width: 18,
              height: 18,
              semanticLabel: label.replaceAll('\n', ' '),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (value.isNotEmpty)
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(color: color, fontSize: 10, height: 1.15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
