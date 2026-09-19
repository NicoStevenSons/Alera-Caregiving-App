import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_spacing.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../domain/models/care_recipient.dart';
import '../../domain/models/caregiver_alert.dart';
import '../../domain/models/caregiver_reminder.dart';
import '../../data/api/caregiver_patient_api_data_source.dart';
import '../../data/patients/caregiver_patient_controller.dart';
import '../../data/api/dto/patient_dto.dart';
import '../people/patient_access_setup_page.dart';
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
  final PatientAccessStatus? patientAccessStatus;
  final VoidCallback? onPatientAccessAction;
  final ValueChanged<String>? onVitalTap;

  const CaregiverPatientDetailPage({
    super.key,
    required this.careRecipient,
    required this.alerts,
    required this.reminders,
    required this.onViewAllAlerts,
    required this.onViewAllReminders,
    required this.onAlertTap,
    this.onMarkAsSeen,
    this.patientAccessStatus,
    this.onPatientAccessAction,
    this.onVitalTap,
  });

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openContactApp(
    BuildContext context, {
    required String scheme,
    required String appLabel,
  }) async {
    final phoneNumber = careRecipient.phoneNumber?.trim();
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showFeedback(
        context,
        'No phone number is saved for ${careRecipient.name}.',
      );
      return;
    }

    final uri = Uri(scheme: scheme, path: phoneNumber);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        _showFeedback(context, 'Unable to open the $appLabel app.');
      }
    } catch (_) {
      if (context.mounted) {
        _showFeedback(context, 'Unable to open the $appLabel app.');
      }
    }
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'Call':
        await _openContactApp(context, scheme: 'tel', appLabel: 'calling');
        return;
      case 'Message':
        await _openContactApp(context, scheme: 'sms', appLabel: 'messaging');
        return;
      default:
        _showFeedback(context, '$action is mock-only for now.');
    }
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
              onAction: (action) => _handleAction(context, action),
            ),
            const SizedBox(height: 12),
            _DashboardCounters(careRecipient: careRecipient),
            const SizedBox(height: 12),
            PatientCareStatusCard(careRecipient: careRecipient),
            const SizedBox(height: 12),
            if (patientAccessStatus != null) ...[
              _PatientAccessStatusCard(
                status: patientAccessStatus!,
                onAction: onPatientAccessAction,
              ),
              const SizedBox(height: 12),
            ],
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
              onVitalTap: (label) {
                if (onVitalTap != null) {
                  onVitalTap!(label);
                  return;
                }

                _showFeedback(context, '$label history is mock-only for now.');
              },
            ),
            const SizedBox(height: 12),
            PatientRemindersSection(
              reminders: reminders,
              onViewAll: onViewAllReminders,
              onAction: (action) =>
                  _showFeedback(context, '$action is mock-only for now.'),
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
  final CaregiverPatientDataSource? patientDataSource;
  final ValueChanged<String>? onVitalTap;

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
    this.patientDataSource,
    this.onVitalTap,
  });

  @override
  State<CaregiverPatientDetailLoaderPage> createState() =>
      _CaregiverPatientDetailLoaderPageState();
}

class _CaregiverPatientDetailLoaderPageState
    extends State<CaregiverPatientDetailLoaderPage> {
  CareRecipient? _patient;
  PatientAccessStatus? _patientAccessStatus;
  CaregiverPatientApiFailure? _failure;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _patient = null;
        _failure = null;
      });
    }

    try {
      final detailFuture = widget.controller.loadDetail(widget.patientId);
      final devicesFuture = widget.controller.loadMonitoringDevices(
        widget.patientId,
      );

      final detail = await detailFuture;
      final devices = await devicesFuture;

      if (mounted) {
        setState(() {
          _patient = patientDetailToCareRecipient(
            detail,
            monitoringDevices: devices,
          );
          _patientAccessStatus = detail.patientAccessStatus;
        });
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
        patientAccessStatus: _patientAccessStatus,
        onPatientAccessAction: _openPatientAccess,
        onVitalTap: widget.onVitalTap,
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

  Future<void> _openPatientAccess() async {
    final status = _patientAccessStatus;
    final patient = _patient;
    final source = widget.patientDataSource;
    if (status == null || patient == null || source == null) return;
    final result = await Navigator.push<PatientAccessSetupResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAccessSetupPage(
          patientId: patient.id,
          patientName: patient.name,
          patientAccess: status,
          dataSource: source,
          loadPatientDetail: widget.controller.loadDetail,
        ),
      ),
    );
    if (result == PatientAccessSetupResult.changed && mounted) _load();
  }
}

class _PatientAccessStatusCard extends StatelessWidget {
  final PatientAccessStatus status;
  final VoidCallback? onAction;

  const _PatientAccessStatusCard({required this.status, this.onAction});

  @override
  Widget build(BuildContext context) {
    final label = switch (status.status) {
      PatientAccessState.notConnected => 'Patient access not connected',
      PatientAccessState.invitePending => 'Invitation pending',
      PatientAccessState.connected => 'Patient access connected',
      PatientAccessState.unknown => 'Patient access status unavailable',
    };
    final detail = switch (status.status) {
      PatientAccessState.invitePending when status.pendingExpiresAt != null =>
        'Invitation expires ${_dateTime(status.pendingExpiresAt!)}',
      PatientAccessState.connected when status.connectedAt != null =>
        'Connected ${_dateTime(status.connectedAt!)}',
      _ => null,
    };
    return AleraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient access'),
          const SizedBox(height: 4),
          Text(label),
          if (detail != null) ...[const SizedBox(height: 4), Text(detail)],
          if (onAction != null &&
              status.status == PatientAccessState.notConnected)
            AleraButton(label: 'Connect patient access', onPressed: onAction!),
          if (onAction != null &&
              status.status == PatientAccessState.invitePending)
            AleraButton(label: 'Open invitation', onPressed: onAction!),
          if (onAction != null && status.status == PatientAccessState.connected)
            AleraButton(label: 'Generate login code', onPressed: onAction!),
        ],
      ),
    );
  }
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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
