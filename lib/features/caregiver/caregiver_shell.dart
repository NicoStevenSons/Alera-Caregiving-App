import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/alera_spacing.dart';
import '../../design_system/alera_theme.dart';

import '../../design_system/alera_typography.dart';
import 'domain/repositories/caregiver_repository.dart';
import 'domain/models/care_recipient.dart';
import 'domain/models/caregiver_alert.dart';
import 'data/api/caregiver_alert_api_data_source.dart';
import 'data/alerts/caregiver_alert_controller.dart';
import 'data/api/caregiver_patient_api_data_source.dart';
import 'data/api/dto/patient_dto.dart';
import 'data/patients/caregiver_patient_controller.dart';
import 'domain/models/health_snapshot.dart';
import 'presentation/home/caregiver_home_page.dart';
import 'presentation/alerts/caregiver_alerts_page.dart';
import 'presentation/alerts/caregiver_alert_detail_page.dart';
import 'presentation/patient_detail/caregiver_patient_detail_page.dart';
import 'presentation/people/caregiver_people_page.dart';
import 'presentation/people/add_patient_page.dart';
import 'presentation/widgets/caregiver_page_app_bar.dart';
import '../../services/alert_notification.dart';

class CaregiverShell extends StatefulWidget {
  final CaregiverRepository repository;
  final CaregiverAlertDataSource? alertDataSource;
  final CaregiverPatientDataSource? patientDataSource;
  final CaregiverPatientController? patientController;
  final String? householdCode;
  final VoidCallback? onSignOut;
  final Future<CaregiverAlert> Function(String)? loadNotificationAlert;
  final NotificationTapBus? notificationTapBus;

  const CaregiverShell({
    super.key,
    required this.repository,
    this.alertDataSource,
    this.patientDataSource,
    this.patientController,
    this.householdCode,
    this.onSignOut,
    this.loadNotificationAlert,
    this.notificationTapBus,
  });

  @override
  State<CaregiverShell> createState() => _CaregiverShellState();
}

class _CaregiverShellState extends State<CaregiverShell> {
  int _selectedIndex = 0;
  String? _selectedPatientId;
  void Function()? _unsubscribeNotifications;
  int _notificationRevision = 0;
  late final CareRecipient _homeCareRecipient;
  late final List<CareRecipient> _careRecipients;
  late final CaregiverAlertController _alertController;
  CaregiverPatientController? _patientController;
  bool _ownsPatientController = false;

  @override
  void initState() {
    super.initState();
    _careRecipients = widget.repository.getCareRecipients().toList();
    _homeCareRecipient = _careRecipients.first;
    final CaregiverAlertDataSource alertLoader =
        widget.alertDataSource ?? _RepositoryAlertDataSource(widget.repository);
    _alertController = CaregiverAlertController(
      loader: alertLoader,
      actions: alertLoader is CaregiverAlertActionDataSource
          ? alertLoader as CaregiverAlertActionDataSource
          : null,
      fallback: widget.repository.getAlerts(),
    )..addListener(_alertsChanged);
    _alertController.load();
    _patientController = widget.patientController;
    final source = widget.patientDataSource;
    if (_patientController == null &&
        source is CaregiverPatientReadDataSource) {
      _ownsPatientController = true;
      _patientController = CaregiverPatientController(
        dataSource: source as CaregiverPatientReadDataSource,
        demoPatients: _careRecipients,
      )..load();
    }
    // AuthGate supplies this loader only for an active caregiver session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.loadNotificationAlert == null) return;
      _unsubscribeNotifications =
          (widget.notificationTapBus ?? NotificationTapBus.instance).subscribe(
            _openNotificationAlert,
          );
    });
  }

  @override
  void dispose() {
    _unsubscribeNotifications?.call();
    _alertController
      ..removeListener(_alertsChanged)
      ..dispose();
    if (_ownsPatientController) _patientController?.dispose();
    super.dispose();
  }

  void _alertsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openNotificationAlert(AlertNotification event) async {
    final revision = ++_notificationRevision;
    try {
      final alert = await widget.loadNotificationAlert!(event.alertId);
      if (!mounted || revision != _notificationRevision) return;
      _alertController.upsert(alert);
      if (alert.id.toLowerCase() != event.alertId ||
          alert.status == CaregiverAlertStatus.resolved ||
          alert.status == CaregiverAlertStatus.falseAlarm) {
        _notificationUnavailable();
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() => _selectedIndex = 2);
      _openAlertDetail(context, alert);
    } catch (error) {
      if (!mounted || revision != _notificationRevision) return;
      // The API clears a 401 session; let AuthGate discard its routes.
      if (error is CaregiverAlertsAuthFailure && error.statusCode == 401) {
        return;
      }
      _notificationUnavailable();
    }
  }

  void _notificationUnavailable() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _selectedIndex = 2);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This alert is no longer available.')),
    );
  }

  void _openCareRecipient(BuildContext context, CareRecipient careRecipient) {
    if (careRecipient.backendBacked && _patientController != null) {
      setState(() => _selectedPatientId = careRecipient.id);
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => CaregiverPatientDetailLoaderPage(
            patientId: careRecipient.id,
            controller: _patientController!,
            alerts: _alertController.alerts
                .where((alert) => alert.careRecipientId == careRecipient.id)
                .toList(),
            reminders: widget.repository
                .getReminders()
                .where((item) => item.careRecipientId == careRecipient.id)
                .toList(),
            onViewAllAlerts: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
            onViewAllReminders: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 3);
            },
            onAlertTap: (alert) => _openAlertDetail(context, alert),
            onMarkAsSeen: _markAsSeen,
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CaregiverPatientDetailPage(
          careRecipient: careRecipient,
          alerts: _alertController.alerts
              .where((alert) => alert.careRecipientId == careRecipient.id)
              .toList(),
          reminders: widget.repository
              .getReminders()
              .where((reminder) => reminder.careRecipientId == careRecipient.id)
              .toList(),
          onViewAllAlerts: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 2);
          },
          onViewAllReminders: () {
            Navigator.pop(context);
            setState(() => _selectedIndex = 3);
          },
          onAlertTap: (alert) => _openAlertDetail(context, alert),
          onMarkAsSeen: _markAsSeen,
        ),
      ),
    );
  }

  void _openAddPatient(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddPatientPage(
          dataSource:
              widget.patientDataSource ?? CaregiverPatientApiDataSource(),
          householdCode: widget.householdCode,
          onPatientCreated: _addCreatedPatient,
        ),
      ),
    );
  }

  Future<void> _addCreatedPatient(PatientCreatedResponse patient) async {
    if (_patientController != null) {
      await _patientController!.refreshAfterCreate(patient.patientId);
      return;
    }
    if (_careRecipients.any((item) => item.id == patient.patientId)) return;
    setState(() {
      _careRecipients.add(
        CareRecipient(
          id: patient.patientId,
          name: patient.fullName,
          relationshipLabel: 'Under your care',
          status: CareStatus.stable,
          alertCount: 0,
          reminderCount: 0,
          quickMessages: const [],
          healthSnapshot: HealthSnapshot(
            heartRateBpm: patient.baselineHeartRate?.round(),
            spo2Percent: patient.baselineSpo2,
            steps: null,
            stressLabel: 'No data',
            sleepDuration: Duration.zero,
            careRiskScore: 0,
            careRiskLabel: 'Not assessed',
            lastCheckIn: patient.createdAt,
            devices: const [],
          ),
        ),
      );
    });
  }

  void _openAlertDetail(BuildContext context, CaregiverAlert alert) {
    CareRecipient? recipient;
    for (final CareRecipient candidate in _careRecipients) {
      if (candidate.id == alert.careRecipientId) {
        recipient = candidate;
        break;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CaregiverAlertDetailPage(
          alert: alert,
          careRecipient: recipient,
          alertController: _alertController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SystemUiOverlayStyle systemBarStyle = _selectedIndex == 0
        ? const SystemUiOverlayStyle(
            statusBarColor: Color(0xFFC3A7F5),
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemStatusBarContrastEnforced: false,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Theme.of(context).colorScheme.surface,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemStatusBarContrastEnforced: false,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemBarStyle,
      child: Theme(
        data: AleraTheme.caregiver(Theme.of(context)),
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: SafeArea(
                bottom: false,
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildHome(context),
                    CaregiverPeoplePage(
                      careRecipients: _careRecipients,
                      controller: _patientController,
                      onCareRecipientSelected: (careRecipient) =>
                          _openCareRecipient(context, careRecipient),
                      onAddPatient: () => _openAddPatient(context),
                    ),
                    CaregiverAlertsPage(
                      alerts: widget.repository.getAlerts(),
                      careRecipients: _careRecipients,
                      controller: _alertController,
                      onAlertTap: (alert) => _openAlertDetail(context, alert),
                    ),
                    const _PlaceholderPage(
                      title: 'Reminders',
                      isTemporary: true,
                    ),
                    _PlaceholderPage(
                      title: 'More',
                      isTemporary: true,
                      onSignOut: widget.onSignOut,
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface, // Matches the navbar background
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.06,
                      ), // Subtle shadow
                      blurRadius: 5,
                      offset: const Offset(
                        0,
                        -3,
                      ), // Negative Y casts the shadow upward
                    ),
                  ],
                ),
                child: NavigationBar(
                  elevation:
                      0, // Removes M3's default tint elevation so your custom shadow handles depth
                  height: 68,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: 'People',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.notifications_none),
                      selectedIcon: Icon(Icons.notifications),
                      label: 'Alerts',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.schedule_outlined),
                      selectedIcon: Icon(Icons.schedule),
                      label: 'Reminders',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.menu),
                      label: 'More',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markAsSeen(CaregiverAlert alert) async {
    if (!_alertController.supportsActions ||
        _alertController.isBusy(alert.id) ||
        alert.status != CaregiverAlertStatus.active) {
      return;
    }
    try {
      await _alertController.acknowledge(alert.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We couldn’t update this alert. Please try again.'),
          ),
        );
      }
    }
  }

  Widget _buildHome(BuildContext context) {
    final controller = _patientController;
    if (controller == null) return _homeDashboard(context, _homeCareRecipient);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.state == CaregiverPatientListState.initialLoading) {
          return const Center(
            key: Key('home-patient-loading'),
            child: CircularProgressIndicator(),
          );
        }
        if (controller.state == CaregiverPatientListState.empty) {
          return const _HomePatientState(
            key: Key('home-patient-empty'),
            icon: Icons.person_search_outlined,
            message: 'No assigned patients yet.',
          );
        }
        if (controller.state == CaregiverPatientListState.error) {
          final forbidden =
              controller.failureKind == CaregiverPatientFailureKind.forbidden;
          return _HomePatientState(
            key: Key(
              forbidden ? 'home-patient-forbidden' : 'home-patient-error',
            ),
            icon: forbidden ? Icons.lock_outline : Icons.cloud_off,
            message: controller.errorMessage ?? 'Unable to load patients.',
            actionLabel: forbidden ? null : 'Retry',
            onAction: forbidden ? null : controller.load,
          );
        }
        final patients = controller.visiblePatients;
        if (patients.isEmpty) {
          return const _HomePatientState(
            icon: Icons.person_search_outlined,
            message: 'No assigned patients yet.',
          );
        }
        final selected = patients.where(
          (patient) => patient.id == _selectedPatientId,
        );
        return _homeDashboard(
          context,
          selected.isEmpty ? patients.first : selected.first,
          showDemo: controller.state == CaregiverPatientListState.demoFallback,
        );
      },
    );
  }

  Widget _homeDashboard(
    BuildContext context,
    CareRecipient patient, {
    bool showDemo = false,
  }) => CaregiverHomePage(
    careRecipient: patient,
    showDemoBanner: showDemo,
    alerts: _alertController.alerts
        .where(
          (alert) =>
              alert.careRecipientId == patient.id &&
              alert.status == CaregiverAlertStatus.active,
        )
        .toList(),
    reminders: widget.repository
        .getReminders()
        .where((reminder) => reminder.careRecipientId == patient.id)
        .toList(),
    onViewAllAlerts: () => setState(() => _selectedIndex = 2),
    onViewAllReminders: () => setState(() => _selectedIndex = 3),
    onAlertTap: (alert) => _openAlertDetail(context, alert),
    onMarkAsSeen: _markAsSeen,
  );
}

class _HomePatientState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _HomePatientState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        if (actionLabel != null) ...[
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class _RepositoryAlertDataSource implements CaregiverAlertDataSource {
  final CaregiverRepository repository;

  const _RepositoryAlertDataSource(this.repository);

  @override
  Future<List<CaregiverAlert>> fetchAlerts() async => repository.getAlerts();
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final bool isTemporary;
  final VoidCallback? onSignOut;

  const _PlaceholderPage({
    required this.title,
    this.isTemporary = false,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CaregiverPageAppBar(title: title),
      body: Padding(
        padding: const EdgeInsets.all(AleraSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onSignOut != null)
              TextButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            const Spacer(),
            Center(
              child: Text(
                isTemporary
                    ? 'Temporary $title placeholder'
                    : '$title screen placeholder',
                style: AleraTypography.body,
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
