import 'package:flutter/material.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_spacing.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_confirmation_dialog.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_skeleton.dart';
import '../../domain/models/care_recipient.dart';
import '../../domain/models/caregiver_alert.dart';
import '../../domain/models/caregiver_reminder.dart';
import '../../data/api/caregiver_patient_api_data_source.dart';
import '../../data/api/caregiver_patient_edit_data_source.dart';
import '../../data/patients/edit_patient_controller.dart';
import '../people/edit_patient_page.dart';
import '../../data/patients/caregiver_patient_controller.dart';
import '../../data/api/dto/monitoring_device_dto.dart';
import '../../data/api/dto/patient_dto.dart';
import '../people/patient_access_setup_page.dart';
import 'widgets/care_status_card.dart';
import 'widgets/patient_needs_attention.dart';
import 'widgets/patient_reminders_section.dart';
import 'widgets/monitoring_devices_card.dart';
import 'widgets/patient_summary_card.dart';
import 'widgets/patient_vital_summary_section.dart';
import '../../../../design_system/widgets/alera_snackbar.dart';

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

  /// Shows the Edit patient action in the app bar when provided.
  final VoidCallback? onEdit;

  /// Opens the create-reminder drawer for this patient. Null on the mock
  /// repository path, where "Reminder" falls back to the mock snackbar.
  final VoidCallback? onNewReminder;
  final ValueChanged<CaregiverReminder>? onCompleteReminder;

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
    this.onEdit,
    this.onNewReminder,
    this.onCompleteReminder,
  });

  void _showFeedback(BuildContext context, String message) {
    showAleraSnackBar(context, message, type: AleraSnackBarType.info);
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
      case 'Reminder':
        if (onNewReminder != null) {
          onNewReminder!();
          return;
        }
        _showFeedback(context, 'Reminders are coming soon for this patient.');
        return;
      default:
        _showFeedback(context, '$action is coming soon.');
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
          color: AleraColors.selected,
        ),
        actions: [
          if (onEdit != null)
            IconButton(
              key: const Key('edit-patient-button'),
              tooltip: 'Edit patient',
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 22),
              color: AleraColors.primary,
            ),
        ],
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
            PatientStatusSummaryCard(
              status: careRecipient.status,
              activeAlertCount: alerts
                  .where((a) => a.status == CaregiverAlertStatus.active)
                  .length,
              careRiskScore: careRecipient.healthSnapshot.careRiskScore,
              careRiskLabel: careRecipient.healthSnapshot.careRiskLabel,
            ),
            const SizedBox(height: 12),
            PatientNeedsAttention(
              alerts: alerts,
              onViewHistory: onViewAllAlerts,
              onAlertTap: onAlertTap,
              onMarkAsSeen: onMarkAsSeen,
            ),
            const SizedBox(height: 20),
            PatientVitalSummarySection(
              snapshot: careRecipient.healthSnapshot,
              onVitalTap: (label) {
                if (onVitalTap != null) {
                  onVitalTap!(label);
                  return;
                }

                _showFeedback(context, '$label history is coming soon.');
              },
            ),
            const SizedBox(height: 20),
            PatientRemindersSection(
              reminders: reminders,
              onViewAll: onViewAllReminders,
              onCompleteReminder: onCompleteReminder,
              onNewReminder:
                  onNewReminder ??
                  () => _showFeedback(
                    context,
                    'Reminders are coming soon for this patient.',
                  ),
            ),
            const SizedBox(height: 12),
            PatientMonitoringDevicesCard(
              devices: careRecipient.healthSnapshot.devices,
            ),
            if (patientAccessStatus != null) ...[
              const SizedBox(height: 12),
              _PatientAccessStatusCard(
                status: patientAccessStatus!,
                onAction: onPatientAccessAction,
              ),
            ],
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
  final CaregiverPatientEditDataSource? patientEditDataSource;
  final ValueChanged<String>? onVitalTap;
  final VoidCallback? onNewReminder;
  final ValueChanged<CaregiverReminder>? onCompleteReminder;

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
    this.patientEditDataSource,
    this.onVitalTap,
    this.onNewReminder,
    this.onCompleteReminder,
  });

  @override
  State<CaregiverPatientDetailLoaderPage> createState() =>
      _CaregiverPatientDetailLoaderPageState();
}

class _CaregiverPatientDetailLoaderPageState
    extends State<CaregiverPatientDetailLoaderPage> {
  CareRecipient? _patient;
  PatientDetailDto? _detail;
  List<MonitoringDeviceDto> _devices = const [];
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
          _detail = detail;
          _devices = devices;
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

  Future<void> _openEdit() async {
    final detail = _detail;
    final photoSource = widget.patientDataSource;
    if (detail == null || photoSource == null) return;
    final result = await Navigator.of(context).push<EditPatientResult>(
      MaterialPageRoute<EditPatientResult>(
        builder: (_) => EditPatientPage(
          patient: detail,
          editDataSource:
              widget.patientEditDataSource ??
              const UnavailablePatientEditDataSource(),
          photoDataSource: photoSource,
        ),
      ),
    );
    if (result == null || !mounted) return;
    // Show the saved values straight away, then let the People list follow.
    setState(() {
      _detail = result.patient;
      _patient = patientDetailToCareRecipient(
        result.patient,
        monitoringDevices: _devices,
      );
    });
    widget.controller.applyPatientUpdate(result.patient);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.photoFailed
                ? 'Changes saved, but the new photo could not be uploaded.'
                : 'Patient updated.',
          ),
        ),
      );
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
        onEdit: widget.patientDataSource == null ? null : _openEdit,
        onNewReminder: widget.onNewReminder,
        onCompleteReminder: widget.onCompleteReminder,
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
          color: AleraColors.selected,
        ),
      ),
      body: failure == null
          ? const _PatientDetailLoadingSkeleton()
          : Center(
              child: Column(
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
    final bool regenerate = status.status == PatientAccessState.connected;
    if (regenerate) {
      final confirmed = await showAleraConfirmationDialog(
        context,
        icon: Icons.autorenew,
        title: 'Generate a new login code?',
        message:
            'Use this when ${patient.name} needs to sign in on a new or '
            'reset phone. Any older unused code will stop working.',
        cancelLabel: 'Cancel',
        confirmLabel: 'Generate code',
      );
      if (confirmed != true || !mounted) return;
    }
    final result = await Navigator.push<PatientAccessSetupResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAccessSetupPage(
          patientId: patient.id,
          patientName: patient.name,
          patientAccess: status,
          dataSource: source,
          loadPatientDetail: widget.controller.loadDetail,
          issueOnOpen: regenerate,
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
      PatientAccessState.notConnected => 'Not connected',
      PatientAccessState.invitePending => 'Invitation pending',
      PatientAccessState.connected => 'Connected',
      PatientAccessState.unknown => 'Status unavailable',
    };
    final detail = switch (status.status) {
      PatientAccessState.invitePending when status.pendingExpiresAt != null =>
        'Expires ${_dateTime(status.pendingExpiresAt!)}',
      PatientAccessState.connected when status.connectedAt != null =>
        'Since ${_dateTime(status.connectedAt!)}',
      _ => null,
    };
    final actionLabel = switch (status.status) {
      PatientAccessState.notConnected => 'Connect patient access',
      PatientAccessState.invitePending => 'Open invitation',
      PatientAccessState.connected => 'Generate login code',
      PatientAccessState.unknown => null,
    };
    return AleraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AleraColors.primarySoft.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.smartphone,
                  size: 22,
                  color: AleraColors.selected,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient app access',
                      style: AleraTypography.sectionTitle.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail == null ? label : '$label · $detail',
                      style: AleraTypography.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            AleraButton(
              label: actionLabel,
              variant: AleraButtonVariant.lightPill,
              height: 42,
              onPressed: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

String _dateTime(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  return '${months[local.month - 1]} ${local.day}, $hour:'
      '${local.minute.toString().padLeft(2, '0')} '
      '${local.hour >= 12 ? 'PM' : 'AM'}';
}

class _PatientDetailLoadingSkeleton extends StatelessWidget {
  const _PatientDetailLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('patient-detail-loading'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AleraSpacing.medium,
        AleraSpacing.small,
        AleraSpacing.medium,
        AleraSpacing.medium,
      ),
      children: const [
        _PatientSummarySkeleton(),
        SizedBox(height: 12),

        _PatientSectionSkeleton(lineWidths: [.72, .48]),
        SizedBox(height: 12),

        _PatientSectionSkeleton(lineWidths: [.62, .38]),
        SizedBox(height: 12),

        _PatientSectionSkeleton(lineWidths: [.82, .55]),
        SizedBox(height: 12),

        _PatientSectionSkeleton(lineWidths: [.68, .46, .58]),
      ],
    );
  }
}

class _PatientSummarySkeleton extends StatelessWidget {
  const _PatientSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      child: Row(
        children: [
          const AleraSkeletonCircle(size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AleraSkeletonBar(widthFactor: .62, height: 14),
                SizedBox(height: 9),
                AleraSkeletonBar(widthFactor: .42, height: 10),
                SizedBox(height: 9),
                AleraSkeletonBar(widthFactor: .52, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientSectionSkeleton extends StatelessWidget {
  final List<double> lineWidths;

  const _PatientSectionSkeleton({required this.lineWidths});

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AleraSkeletonBar(widthFactor: .38, height: 14),
          const SizedBox(height: 14),
          for (int index = 0; index < lineWidths.length; index++) ...[
            AleraSkeletonBar(
              widthFactor: lineWidths[index],
              height: index == 0 ? 12 : 10,
            ),
            if (index != lineWidths.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
