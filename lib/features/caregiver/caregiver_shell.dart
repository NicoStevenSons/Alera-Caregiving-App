import 'presentation/home/widgets/home_loading_skeleton.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import '../../design_system/alera_colors.dart';
import '../../design_system/alera_spacing.dart';
import '../../design_system/alera_theme.dart';
import '../../design_system/widgets/alera_card.dart';
import '../../design_system/status/status.dart';

import '../../design_system/alera_typography.dart';
import 'domain/repositories/caregiver_repository.dart';
import 'domain/models/care_recipient.dart';
import 'domain/models/caregiver_alert.dart';
import 'data/api/caregiver_alert_api_data_source.dart';
import 'data/alerts/caregiver_alert_controller.dart';
import 'data/api/caregiver_patient_api_data_source.dart';
import 'data/api/caregiver_nudge_api_data_source.dart';
import 'data/api/dto/patient_dto.dart';
import 'data/patients/caregiver_patient_controller.dart';
import 'data/patients/caregiver_patient_selection_controller.dart';
import 'data/patients/caregiver_patient_selection_store.dart';
import 'data/api/caregiver_activity_trend_api_data_source.dart';
import 'data/api/caregiver_sleep_trend_api_data_source.dart';
import 'data/api/caregiver_vital_trend_api_data_source.dart';
import 'data/api/dto/vital_trend_dto.dart';
import 'presentation/vitals/caregiver_activity_trend_page.dart';
import 'presentation/vitals/caregiver_sleep_trend_page.dart';
import 'presentation/vitals/caregiver_vital_trend_page.dart';
import 'domain/models/health_snapshot.dart';
import 'domain/models/caregiver_nudge.dart';
import 'presentation/home/caregiver_home_page.dart';
import 'presentation/alerts/caregiver_alerts_page.dart';
import 'presentation/alerts/caregiver_alert_detail_page.dart';
import 'presentation/patient_detail/caregiver_patient_detail_page.dart';
import 'presentation/people/caregiver_people_page.dart';
import 'presentation/people/add_patient_page.dart';
import 'presentation/widgets/caregiver_page_app_bar.dart';
import '../../services/alert_notification.dart';
import '../reminders/data/reminder_api_data_source.dart';
import '../reminders/data/reminder_controller.dart';
import '../reminders/data/home_reminder_controller.dart';
import '../reminders/domain/reminder_models.dart';
import 'domain/models/caregiver_reminder.dart';
import '../reminders/presentation/caregiver_reminders_page.dart';
import '../reminders/presentation/create_reminder_sheet.dart';
import '../reminders/presentation/reminder_action_runner.dart';
import '../startup/presentation/alera_startup_screen.dart';
import '../../design_system/widgets/alera_snackbar.dart';
import '../../design_system/widgets/alera_empty_state.dart';

class CaregiverShell extends StatefulWidget {
  final CaregiverRepository repository;
  final CaregiverAlertDataSource? alertDataSource;
  final CaregiverPatientDataSource? patientDataSource;
  final CaregiverPatientController? patientController;
  final String? householdCode;
  final String? caregiverId;
  final CaregiverPatientSelectionStore? patientSelectionStore;
  final VoidCallback? onSignOut;
  final Future<CaregiverAlert> Function(String)? loadNotificationAlert;
  final NotificationTapBus? notificationTapBus;
  final AlertNotificationArrivalBus? alertArrivalBus;
  final CaregiverNudgeDataSource? nudgeDataSource;
  final ReminderDataSource? reminderDataSource;
  final Duration patientPollingInterval;

  const CaregiverShell({
    super.key,
    required this.repository,
    this.alertDataSource,
    this.patientDataSource,
    this.patientController,
    this.householdCode,
    this.caregiverId,
    this.patientSelectionStore,
    this.onSignOut,
    this.loadNotificationAlert,
    this.notificationTapBus,
    this.alertArrivalBus,
    this.nudgeDataSource,
    this.reminderDataSource,
    this.patientPollingInterval = const Duration(seconds: 15),
  });

  @override
  State<CaregiverShell> createState() => _CaregiverShellState();
}

class _CaregiverShellState extends State<CaregiverShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final CaregiverPatientSelectionController _patientSelection;
  String? get _selectedPatientId => _patientSelection.selectedPatientId;
  void Function()? _unsubscribeNotifications;
  void Function()? _unsubscribeAlertArrivals;
  int _notificationRevision = 0;
  late final CareRecipient _homeCareRecipient;
  late final List<CareRecipient> _careRecipients;
  late final CaregiverAlertController _alertController;
  CaregiverPatientController? _patientController;
  bool _ownsPatientController = false;
  bool _sendingNudge = false;
  bool _patientRefreshInFlight = false;
  bool _appResumed = true;
  Timer? _patientPollTimer;
  late final ReminderController _reminderController;
  HomeReminderController? _homeReminderController;

  void _homeRemindersChanged() {
    if (mounted) setState(() {});
  }

  List<CaregiverReminder> _homeReminderItems(CareRecipient patient) {
    if (!patient.backendBacked) {
      return widget.repository
          .getReminders()
          .where((reminder) => reminder.careRecipientId == patient.id)
          .toList();
    }
    final controller = _homeReminderController;
    if (controller == null || controller.patientId != patient.id) {
      return const [];
    }
    return controller.occurrences
        .where((item) => item.status != ReminderOccurrenceStatus.canceled)
        .map(
          (item) => CaregiverReminder(
            id: item.id,
            careRecipientId: item.patientId,
            title: item.title,
            description: item.instructions ?? '',
            scheduledAt: item.scheduledAt.toUtc().add(const Duration(hours: 8)),
            status: switch (item.status) {
              ReminderOccurrenceStatus.missed => CaregiverReminderStatus.missed,
              ReminderOccurrenceStatus.completed ||
              ReminderOccurrenceStatus.completedLate =>
                CaregiverReminderStatus.completed,
              _ => CaregiverReminderStatus.upcoming,
            },
            statusLabel: switch (item.status) {
              ReminderOccurrenceStatus.upcoming => 'Upcoming',
              ReminderOccurrenceStatus.due => 'Due',
              ReminderOccurrenceStatus.snoozed => 'Snoozed',
              ReminderOccurrenceStatus.completed => 'Completed',
              ReminderOccurrenceStatus.completedLate => 'Completed late',
              ReminderOccurrenceStatus.missed => 'Missed',
              ReminderOccurrenceStatus.canceled => 'Canceled',
            },
          ),
        )
        .toList();
  }

  List<CareRecipient> get _selectionPatients =>
      _patientController?.visiblePatients ?? _careRecipients;

  void _reconcilePatientSelection() {
    final controller = _patientController;
    if (controller != null &&
        (controller.isRefreshing ||
            controller.errorMessage != null ||
            (controller.state != CaregiverPatientListState.success &&
                controller.state != CaregiverPatientListState.empty))) {
      return;
    }
    _patientSelection.reconcile(
      _selectionPatients
          .where(
            (patient) => widget.caregiverId == null || patient.backendBacked,
          )
          .map((patient) => patient.id)
          .toList(),
    );
  }

  bool _dashboardStartupComplete = false;
  bool _patientSelectionRestored = false;

  CareRecipient? get _selectedDashboardPatient {
    final controller = _patientController;
    if (controller != null &&
        controller.state != CaregiverPatientListState.success) {
      return null;
    }
    final patients = _selectionPatients;
    if (patients.isEmpty) return null;
    return patients.firstWhere(
      (patient) => patient.id == _selectedPatientId,
      orElse: () => patients.first,
    );
  }

  void _prepareHomeReminders() {
    if (!_patientSelectionRestored) return;
    final patient = _selectedDashboardPatient;
    final controller = _homeReminderController;
    if (patient == null || !patient.backendBacked || controller == null) return;
    unawaited(controller.ensureLoaded(patient.id));
  }

  bool get _dashboardNeedsInitialData {
    final patient = _selectedDashboardPatient;
    if (patient == null || !patient.backendBacked) return false;
    if (!_patientSelectionRestored || !_alertController.hasLoaded) return true;
    final reminders = _homeReminderController;
    return reminders != null &&
        (reminders.patientId != patient.id ||
            (reminders.loading && !reminders.hasLoaded));
  }

  Future<void> _restorePatientSelection() async {
    await _patientSelection.restore();
    if (!mounted) return;
    _patientSelectionRestored = true;
    _patientsChanged();
  }

  void _selectPatient(String patientId) {
    final ids = _selectionPatients
        .where((patient) => widget.caregiverId == null || patient.backendBacked)
        .map((patient) => patient.id)
        .toList();
    if (_patientSelection.select(patientId, ids) && mounted) {
      _prepareHomeReminders();
      setState(() {});
    }
  }

  void _patientsChanged() {
    if (!mounted) return;
    _reconcilePatientSelection();
    _prepareHomeReminders();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _careRecipients = widget.repository.getCareRecipients().toList();
    _homeCareRecipient = _careRecipients.first;
    _patientSelection = CaregiverPatientSelectionController(
      store:
          widget.patientSelectionStore ??
          SecureCaregiverPatientSelectionStore(),
      caregiverId: widget.caregiverId,
    );
    final CaregiverAlertDataSource alertLoader =
        widget.alertDataSource ?? _RepositoryAlertDataSource(widget.repository);
    _alertController = CaregiverAlertController(
      loader: alertLoader,
      actions: alertLoader is CaregiverAlertActionDataSource
          ? alertLoader as CaregiverAlertActionDataSource
          : null,
      timelineSource: alertLoader is CaregiverAlertTimelineDataSource
          ? alertLoader as CaregiverAlertTimelineDataSource
          : null,
      fallback: widget.repository.getAlerts(),
    )..addListener(_alertsChanged);
    final reminderSource = widget.reminderDataSource ?? ReminderApiDataSource();
    _reminderController = ReminderController(dataSource: reminderSource);
    if (reminderSource is ReminderDateRangeDataSource) {
      _homeReminderController = HomeReminderController(
        dataSource: reminderSource as ReminderDateRangeDataSource,
      )..addListener(_homeRemindersChanged);
    }
    _alertController.load();
    if (widget.loadNotificationAlert != null) {
      _unsubscribeAlertArrivals =
          (widget.alertArrivalBus ?? AlertNotificationArrivalBus.instance)
              .subscribe(_receiveAlertNotification);
    }
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
    _patientController?.addListener(_patientsChanged);
    unawaited(_restorePatientSelection());
    _syncPatientPolling();
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
    WidgetsBinding.instance.removeObserver(this);
    _stopPatientPolling();
    _unsubscribeNotifications?.call();
    _unsubscribeAlertArrivals?.call();
    _alertController
      ..removeListener(_alertsChanged)
      ..dispose();
    _patientController?.removeListener(_patientsChanged);

    if (_ownsPatientController) {
      _patientController?.dispose();
    }
    _homeReminderController
      ?..removeListener(_homeRemindersChanged)
      ..dispose();
    _reminderController.dispose();
    super.dispose();
  }

  bool _alertRebuildScheduled = false;

  void _alertsChanged() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_alertRebuildScheduled) return;
      _alertRebuildScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _alertRebuildScheduled = false;
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  Future<void> _refreshPatientsForLiveDashboard() async {
    final controller = _patientController;
    if (controller == null || _patientRefreshInFlight) return;

    _patientRefreshInFlight = true;
    try {
      await controller.load(refresh: true);
    } finally {
      _patientRefreshInFlight = false;
      if (mounted && _selectedIndex == 0) {
        unawaited(_homeReminderController?.refresh() ?? Future<void>.value());
      }
    }
  }

  void _startPatientPolling() {
    if (_patientPollTimer != null ||
        widget.patientPollingInterval <= Duration.zero) {
      return;
    }
    _patientPollTimer = Timer.periodic(widget.patientPollingInterval, (_) {
      unawaited(_refreshPatientsForLiveDashboard());
    });
  }

  void _stopPatientPolling() {
    _patientPollTimer?.cancel();
    _patientPollTimer = null;
  }

  void _syncPatientPolling() {
    final shouldPoll =
        _appResumed && _selectedIndex == 0 && _patientController != null;
    if (shouldPoll) {
      _startPatientPolling();
    } else {
      _stopPatientPolling();
    }
  }

  void _selectDestination(int index) {
    if (_selectedIndex == index) return;

    final enteringHome = index == 0;
    final enteringAlerts = index == 2;
    setState(() => _selectedIndex = index);
    _syncPatientPolling();

    if (enteringHome) {
      unawaited(_refreshPatientsForLiveDashboard());
    }
    if (enteringAlerts) {
      _alertController.load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    if (_appResumed) {
      _alertController.load();
      unawaited(_refreshPatientsForLiveDashboard());
      _reminderController.refresh();
    }
    _syncPatientPolling();
  }

  Future<void> _receiveAlertNotification(AlertNotification event) async {
    final loader = widget.loadNotificationAlert;
    if (loader == null) return;

    try {
      final alert = await loader(event.alertId);
      if (!mounted) return;
      _alertController.upsert(alert);
      unawaited(_refreshPatientsForLiveDashboard());
    } on CaregiverAlertsAuthFailure catch (failure) {
      if (failure.statusCode == 401) return;
    } catch (_) {
      // Resume, Alerts-tab entry, or periodic Home polling will retry.
    }
  }

  Future<void> _openNotificationAlert(AlertNotification event) async {
    final revision = ++_notificationRevision;
    try {
      final alert = await widget.loadNotificationAlert!(event.alertId);
      if (!mounted || revision != _notificationRevision) return;
      _alertController.upsert(alert);
      unawaited(_refreshPatientsForLiveDashboard());
      if (alert.id.toLowerCase() != event.alertId ||
          alert.status == CaregiverAlertStatus.resolved ||
          alert.status == CaregiverAlertStatus.falseAlarm) {
        _notificationUnavailable();
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
      _selectDestination(2);
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
    _selectDestination(2);
    showAleraSnackBar(context, 'This alert is no longer available.', type: AleraSnackBarType.error);
  }

  void _openCareRecipient(BuildContext context, CareRecipient careRecipient) {
    if (careRecipient.backendBacked && _patientController != null) {
      _selectPatient(careRecipient.id);
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => CaregiverPatientDetailLoaderPage(
            patientId: careRecipient.id,
            controller: _patientController!,
            patientDataSource:
                widget.patientDataSource is CaregiverPatientDataSource
                ? widget.patientDataSource as CaregiverPatientDataSource
                : null,
            alerts: _alertController.alerts
                .where((alert) => alert.careRecipientId == careRecipient.id)
                .toList(),
            reminders: widget.repository
                .getReminders()
                .where((item) => item.careRecipientId == careRecipient.id)
                .toList(),
            onViewAllAlerts: () {
              Navigator.pop(context);
              _selectDestination(2);
            },
            onViewAllReminders: () {
              Navigator.pop(context);
              _selectDestination(3);
            },
            onAlertTap: (alert) => _openAlertDetail(context, alert),
            onMarkAsSeen: _markAsSeen,
            onVitalTap: (metric) =>
                _openVitalTrend(context, careRecipient, metric),
            onNewReminder: () => _createReminderFor(context, careRecipient),
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
            _selectDestination(2);
          },
          onViewAllReminders: () {
            Navigator.pop(context);
            _selectDestination(3);
          },
          onAlertTap: (alert) => _openAlertDetail(context, alert),
          onMarkAsSeen: _markAsSeen,
          onVitalTap: (metric) =>
              _openVitalTrend(context, careRecipient, metric),
        ),
      ),
    );
  }

  /// Opens the create-reminder drawer from a patient's page and saves the
  /// result through the shared reminder controller.
  Future<void> _createReminderFor(
    BuildContext context,
    CareRecipient patient,
  ) async {
    final draft = await showCreateReminderSheet(
      context,
      patientId: patient.id,
      patientName: patient.name,
      initialDate: DateTime.now(),
    );
    if (draft == null || !context.mounted) return;
    await runReminderAction(
      context,
      () => _reminderController.createTemplate(draft),
      success: 'Reminder created.',
    );
  }

  void _openAddPatient(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddPatientPage(
          dataSource:
              widget.patientDataSource ?? CaregiverPatientApiDataSource(),
          loadPatientDetail: _patientController?.loadDetail,
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
          profilePhotoUrl: patient.profilePhotoUrl,
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

    final backendPatients = _patientController?.visiblePatients ?? const [];

    for (final candidate in backendPatients) {
      if (candidate.id == alert.careRecipientId) {
        recipient = candidate;
        break;
      }
    }

    if (recipient == null) {
      for (final candidate in _careRecipients) {
        if (candidate.id == alert.careRecipientId) {
          recipient = candidate;
          break;
        }
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
    final patientController = _patientController;

    if (!_dashboardStartupComplete &&
        ((patientController != null &&
                patientController.state ==
                    CaregiverPatientListState.initialLoading) ||
            _dashboardNeedsInitialData)) {
      return const AleraStartupScreen();
    }
    _dashboardStartupComplete = true;

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
                    _buildAlerts(context),
                    _buildReminders(),
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
                  onDestinationSelected: _selectDestination,
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
        showAleraSnackBar(context, 'We couldn’t update this alert. Please try again.', type: AleraSnackBarType.error);
      }
    }
  }

  Widget _buildAlerts(BuildContext context) {
    Widget buildPage(List<CareRecipient> patients) => CaregiverAlertsPage(
      alerts: widget.repository.getAlerts(),
      careRecipients: patients,
      controller: _alertController,
      isActive: _selectedIndex == 2,
      onAlertTap: (alert) => _openAlertDetail(context, alert),
    );

    final controller = _patientController;
    if (controller == null) {
      return buildPage(_careRecipients);
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => buildPage(controller.visiblePatients),
    );
  }

  Widget _buildReminders() {
    Widget buildPage(List<CareRecipient> patients) => CaregiverRemindersPage(
      controller: _reminderController,
      patients: patients.where((patient) => patient.backendBacked).toList(),
      initialPatientId: _selectedPatientId,
    );

    final controller = _patientController;
    if (controller == null) return buildPage(_careRecipients);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => buildPage(controller.visiblePatients),
    );
  }

  Widget _buildHome(BuildContext context) {
    final controller = _patientController;
    if (controller == null) {
      final selected = _careRecipients.where(
        (patient) => patient.id == _selectedPatientId,
      );
      return _homeDashboard(
        context,
        selected.isEmpty ? _homeCareRecipient : selected.first,
        onSelectPatient: _careRecipients.length < 2
            ? null
            : () => _showPatientSelector(context, _careRecipients),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.state == CaregiverPatientListState.initialLoading) {
          return const HomeLoadingSkeleton();
        }
        if (controller.state == CaregiverPatientListState.empty) {
          return const AleraEmptyState(
            key: Key('home-patient-empty'),
            icon: Icons.person_search,
            title: 'No patients yet',
            message: 'No assigned patients yet.',
          );
        }
        if (controller.state == CaregiverPatientListState.error) {
          final forbidden =
              controller.failureKind == CaregiverPatientFailureKind.forbidden;
          return AleraEmptyState(
            key: Key(
              forbidden ? 'home-patient-forbidden' : 'home-patient-error',
            ),
            icon: forbidden ? Icons.lock : null,
            assetPath: forbidden ? null : AleraEmptyState.errorAsset,
            title: forbidden ? 'No access' : 'Couldn’t load patients',
            message: controller.errorMessage ?? 'Unable to load patients.',
            actionLabel: forbidden ? null : 'Retry',
            onAction: forbidden ? null : controller.load,
          );
        }
        final patients = controller.visiblePatients;
        if (patients.isEmpty) {
          return const AleraEmptyState(
            icon: Icons.person_search,
            title: 'No patients yet',
            message: 'No assigned patients yet.',
          );
        }
        final selected = patients.where(
          (patient) => patient.id == _selectedPatientId,
        );
        final selectedPatient = selected.isEmpty
            ? patients.first
            : selected.first;
        return _homeDashboard(
          context,
          selectedPatient,
          showDemo: controller.state == CaregiverPatientListState.demoFallback,
          onSelectPatient: patients.length < 2
              ? null
              : () => _showPatientSelector(context, patients),
        );
      },
    );
  }

  Widget _homeDashboard(
    BuildContext context,
    CareRecipient patient, {
    bool showDemo = false,
    VoidCallback? onSelectPatient,
  }) {
    final reminderController = _homeReminderController;
    return CaregiverHomePage(
      careRecipient: patient,
      dataLoading: _dashboardNeedsInitialData,
      showDemoBanner: showDemo,
      alerts: _alertController.alerts
          .where(
            (alert) =>
                alert.careRecipientId == patient.id &&
                alert.status == CaregiverAlertStatus.active,
          )
          .toList(),
      reminders: _homeReminderItems(patient),
      remindersLoading: false,
      remindersError: !patient.backendBacked
          ? null
          : reminderController == null
          ? 'Reminders are unavailable. Please try again later.'
          : reminderController.patientId == patient.id
          ? reminderController.errorMessage
          : null,
      onRetryReminders: reminderController == null
          ? null
          : () => reminderController.loadForPatient(patient.id),
      onViewAllAlerts: () => _selectDestination(2),
      onViewAllReminders: () => _selectDestination(3),
      onAlertTap: (alert) => _openAlertDetail(context, alert),
      onMarkAsSeen: _markAsSeen,
      onSelectPatient: onSelectPatient,
      sendingNudge: _sendingNudge,
      onSendNudge: patient.backendBacked
          ? (type) => _sendNudge(patient, type)
          : null,
      onMetricTap: (metric) => _openVitalTrend(context, patient, metric),
    );
  }

  Future<void> _sendNudge(
    CareRecipient patient,
    CaregiverNudgeType type,
  ) async {
    final source = widget.nudgeDataSource;
    if (source == null || _sendingNudge) return;
    setState(() => _sendingNudge = true);
    try {
      await source.sendNudge(patient.id, type);
      if (!mounted) return;
      showAleraSnackBar(context, '${type.label} sent to ${patient.name}.', type: AleraSnackBarType.success);
    } on CaregiverNudgeFailure catch (failure) {
      if (!mounted || failure.statusCode == 401) return;
      showAleraSnackBar(context, failure.message, type: AleraSnackBarType.error);
    } catch (_) {
      if (!mounted) return;
      showAleraSnackBar(context, 'Unable to send the reminder. Please try again.', type: AleraSnackBarType.error);
    } finally {
      if (mounted) setState(() => _sendingNudge = false);
    }
  }

  void _showPatientSelector(
    BuildContext context,
    List<CareRecipient> patients,
  ) {
    if (patients.length < 2) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AleraColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text('Switch patient', style: AleraTypography.sectionTitle),
              ),
              for (final patient in patients) ...[
                AleraCard(
                  key: ValueKey<String>('patient-switch-${patient.id}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (mounted) {
                      _selectPatient(patient.id);
                    }
                  },
                  child: Row(
                    children: [
                      AleraBadgedAvatar(
                        name: patient.name,
                        photoUrl: patient.profilePhotoUrl,
                        radius: 22,
                        ringColor: AleraColors.surface,
                        status: PatientStatusChip.describe(
                          patient.status,
                          sheetContext,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AleraTypography.sectionTitle.copyWith(
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              patient.relationshipLabel,
                              style: AleraTypography.body.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (patient.id == _selectedPatientId ||
                          (_selectedPatientId == null &&
                              patient == patients.first))
                        const Icon(
                          Icons.check_circle,
                          size: 24,
                          color: AleraColors.selected,
                          semanticLabel: 'Selected',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openVitalTrend(
    BuildContext context,
    CareRecipient patient,
    String metric,
  ) {
    final trendMetric = switch (metric) {
      'Heart Rate' => VitalTrendMetric.heartRate,
      'SpO2' || 'SpO₂' => VitalTrendMetric.spo2,
      _ => null,
    };

    final isActivity = metric == 'Activity';
    final isSleep = metric == 'Sleep';

    if (trendMetric == null && !isActivity && !isSleep) {
      showAleraSnackBar(
        context,
        '$metric history is not available yet.',
        type: AleraSnackBarType.info,
      );
      return;
    }

    if (!patient.backendBacked) {
      showAleraSnackBar(
        context,
        'Trend history is only available for connected patients.',
        type: AleraSnackBarType.info,
      );
      return;
    }

    if (isActivity) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CaregiverActivityTrendPage(
            patientId: patient.id,
            patientName: patient.name,
            dataSource: CaregiverActivityTrendApiDataSource(),
          ),
        ),
      );
      return;
    }

    if (isSleep) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CaregiverSleepTrendPage(
            patientId: patient.id,
            patientName: patient.name,
            dataSource: CaregiverSleepTrendApiDataSource(),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CaregiverVitalTrendPage(
          patientId: patient.id,
          patientName: patient.name,
          metric: trendMetric!,
          dataSource: CaregiverVitalTrendApiDataSource(),
        ),
      ),
    );
  }
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
