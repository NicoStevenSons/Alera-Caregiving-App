import 'dart:async';

import 'package:flutter/material.dart';

import '../features/elderly/data/api/device_status_api_service.dart';
import '../Services/fifo_upload_service.dart';
import '../features/elderly/data/api/health_event_api_service.dart';
import '../Services/phone_heartbeat_service.dart';
import '../Services/upload_queue_service.dart';
import '../Services/watch_listener_controller.dart';
import '../Services/watch_payload_service.dart';

import '../config/app_config.dart';

import '../features/elderly/domain/elderly_home_view_state.dart';
import '../features/elderly/domain/models/elderly_reminder.dart';
import '../features/elderly/presentation/elderly_home_page.dart';
import '../features/elderly/presentation/elderly_more_page.dart';
import '../features/elderly/presentation/elderly_reminders_page.dart';
import '../features/elderly/presentation/patient_reminder_detail_page.dart';
import '../features/elderly/services/reminder_notification_service.dart';
import '../features/reminders/data/reminder_api_data_source.dart';

import '../models/device_status_data.dart';
import '../models/heart_rate_data.dart';
import '../models/sleep_data.dart';
import '../models/spo2_data.dart';
import '../models/steps_data.dart';

import '../services/patient_nudge_notification.dart';
import '../services/reminder_due_notification.dart';
import '../Services/health_connect_refresh_service.dart';
import '../features/elderly/data/api/activity_data_api_service.dart';

class ElderlyInterface extends StatefulWidget {
  final String patientId;
  final VoidCallback? onSignOut;

  const ElderlyInterface({super.key, required this.patientId, this.onSignOut});

  @override
  State<ElderlyInterface> createState() => _ElderlyInterfaceState();
}

class _ElderlyInterfaceState extends State<ElderlyInterface>
    with WidgetsBindingObserver {
  final WatchPayloadService watchPayloadService = WatchPayloadService();

  late final HealthEventApiService healthEventApiService;

  late final ActivityDataApiService activityDataApiService;

  final UploadQueueService uploadQueueService = UploadQueueService();

  final ReminderApiDataSource reminderService = ReminderApiDataSource();

  final HealthConnectRefreshService healthConnectRefreshService =
      HealthConnectRefreshService();

  Timer? _stepsRefreshTimer;

  List<ElderlyReminder> reminders = [];

  bool remindersLoading = true;
  String? remindersError;

  final Set<String> _busyReminderIds = <String>{};

  int _selectedIndex = 0;

  void Function()? _unsubscribeNudges;
  void Function()? _unsubscribeDueReminders;

  late final FifoUploadService fifoUploadService;
  late final WatchListenerController watchListenerController;
  late final PhoneHeartbeatService phoneHeartbeatService;
  late final DeviceStatusApiService deviceStatusApiService;

  HeartRateData heartRateData = const HeartRateData(
    bpm: null,
    status: null,
    measuredAt: null,
  );

  SpO2Data spo2Data = SpO2Data.empty();

  StepsData stepsData = StepsData.empty();

  DeviceStatusData deviceStatusData = DeviceStatusData.empty();

  SleepData sleepData = SleepData.empty();

  @override
  void initState() {
    super.initState();

    healthEventApiService = HealthEventApiService(
      baseUrl: AppConfig.backendBaseUrl,
      patientId: widget.patientId,
    );

    activityDataApiService = ActivityDataApiService(
      baseUrl: AppConfig.backendBaseUrl,
      patientId: widget.patientId,
    );

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _unsubscribeNudges = PatientNudgeTapBus.instance.subscribe(_openNudge);
      _unsubscribeDueReminders = ReminderDueTapBus.instance.subscribe(
        _openDueReminder,
      );
    });

    deviceStatusApiService = DeviceStatusApiService(
      baseUrl: AppConfig.backendBaseUrl,
      patientId: widget.patientId,
    );

    phoneHeartbeatService = PhoneHeartbeatService(
      deviceStatusApiService: deviceStatusApiService,
    );

    fifoUploadService = FifoUploadService(
      uploadQueueService: uploadQueueService,
      healthEventApiService: healthEventApiService,
      expectedPatientId: widget.patientId,
    );

    watchListenerController = WatchListenerController(
      watchPayloadService: watchPayloadService,
      uploadQueueService: uploadQueueService,
      healthEventApiService: healthEventApiService,
      fifoUploadService: fifoUploadService,
      activityDataApiService: activityDataApiService,
      onHeartRateUpdated: (HeartRateData data) {
        if (!mounted) return;

        setState(() {
          heartRateData = data;
          deviceStatusData = deviceStatusData.copyWith(connectedToPhone: true);
        });
      },
      onSpO2Updated: (SpO2Data data) {
        if (!mounted) return;

        setState(() {
          spo2Data = data;
          deviceStatusData = deviceStatusData.copyWith(connectedToPhone: true);
        });
      },
      onStepsUpdated: (StepsData data) {
        if (!mounted) return;

        setState(() {
          stepsData = data;
        });
      },
      onDeviceStatusUpdated: (DeviceStatusData data) {
        if (!mounted) return;

        debugPrint(
          'MAIN RECEIVED DEVICE STATUS: '
          'battery=${data.batteryPercent}, '
          'device=${data.deviceName}, '
          'model=${data.deviceModel}, '
          'connected=${data.connectedToPhone}, '
          'phone=${data.connectedPhoneName}, '
          'charging=${data.isCharging}, '
          'worn=${data.isWorn}',
        );

        setState(() {
          deviceStatusData = deviceStatusData.copyWith(
            batteryPercent: data.batteryPercent,
            deviceName: data.deviceName,
            deviceModel: data.deviceModel,
            connectedToPhone: data.connectedToPhone,
            connectedPhoneName: data.connectedPhoneName,
            isCharging: data.isCharging,
            isWorn: data.isWorn,
            measuredAt: data.measuredAt,
          );
        });

        unawaited(deviceStatusApiService.sendWatchStatus(data));
      },
      onSleepUpdated: (SleepData data) {
        if (!mounted) return;

        setState(() {
          sleepData = data;
        });
      },
    );

    _loadReminders();

    watchListenerController.start();

    unawaited(watchPayloadService.requestWatchStatus());

    phoneHeartbeatService.start();

    _startStepsRefreshTimer();

    _processPendingQueue();
  }

  Future<void> _processPendingQueue() async {
    if (!AppConfig.enableBackend) return;

    debugPrint('Checking pending upload queue...');

    await fifoUploadService.processQueue();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        'App resumed. Refreshing Health Connect '
        'data and processing pending queue.',
      );

      unawaited(healthConnectRefreshService.refreshSteps());

      unawaited(healthConnectRefreshService.refreshSleep());

      unawaited(_processPendingQueue());

      _startStepsRefreshTimer();

      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      debugPrint(
        'App left foreground. '
        'Stopping foreground steps timer.',
      );

      _stepsRefreshTimer?.cancel();
      _stepsRefreshTimer = null;
    }
  }

  Future<void> _loadReminders() async {
    if (mounted) {
      setState(() {
        remindersLoading = true;
        remindersError = null;
      });
    }

    try {
      final result = await reminderService.fetchOccurrences();

      if (!mounted) return;

      setState(() {
        reminders = result.items
            .map(ElderlyReminder.fromOccurrence)
            .toList(growable: false);
        remindersLoading = false;
        remindersError = null;
      });
    } catch (error) {
      debugPrint('Failed to load reminders: $error');

      if (!mounted) return;

      setState(() {
        remindersLoading = false;
        remindersError = error is ReminderApiFailure
            ? error.message
            : 'Unable to load reminders. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _stepsRefreshTimer?.cancel();
    _stepsRefreshTimer = null;

    _unsubscribeNudges?.call();
    _unsubscribeDueReminders?.call();

    phoneHeartbeatService.stop();

    WidgetsBinding.instance.removeObserver(this);

    watchPayloadService.dispose();

    super.dispose();
  }

  void _openNudge(PatientNudgeNotification event) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${event.type.label} reminder received.')),
      );
  }

  void _startStepsRefreshTimer() {
    _stepsRefreshTimer?.cancel();

    debugPrint(
      'Starting 15-minute Health Connect '
      'steps refresh timer.',
    );

    _stepsRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      debugPrint(
        '15-minute Health Connect '
        'steps refresh triggered.',
      );

      unawaited(healthConnectRefreshService.refreshSteps());
    });
  }

  Future<void> _openDueReminder(ReminderDueNotification event) async {
    if (!mounted) return;

    try {
      final occurrence = await reminderService.fetchOccurrence(
        event.occurrenceId,
      );

      if (!mounted) return;

      final reminder = ElderlyReminder.fromOccurrence(occurrence);

      if (event.action == ReminderNotificationAction.complete) {
        await _completeReminder(reminder);
        return;
      }

      if (event.action == ReminderNotificationAction.snooze) {
        await _runReminderAction(
          reminder,
          () =>
              reminderService.snooze(reminder.occurrenceId, snoozeMinutes: 10),
          successMessage: 'Reminder snoozed for 10 minutes.',
        );
        return;
      }

      await _showReminderDetails(reminder);

      if (mounted) await _loadReminders();
    } on ReminderApiFailure catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open this reminder. Please try again.');
      }
    }
  }

  Future<void> _completeReminder(ElderlyReminder reminder) async {
    await _runReminderAction(
      reminder,
      () => reminderService.complete(reminder.occurrenceId),
      successMessage: 'Reminder completed.',
    );
  }

  Future<void> _snoozeReminder(ElderlyReminder reminder) async {
    await _runReminderAction(
      reminder,
      () => reminderService.snooze(
        reminder.occurrenceId,
        snoozeMinutes: reminder.defaultSnoozeMinutes,
      ),
      successMessage:
          'Reminder snoozed for ${reminder.defaultSnoozeMinutes} minutes.',
    );
  }

  Future<void> _runReminderAction(
    ElderlyReminder reminder,
    Future<Object?> Function() action, {
    required String successMessage,
  }) async {
    if (_busyReminderIds.contains(reminder.occurrenceId)) return;

    setState(() => _busyReminderIds.add(reminder.occurrenceId));

    try {
      await action();
      await ReminderNotificationService.instance.cancelReminder(reminder);
      await _loadReminders();

      if (mounted) _showMessage(successMessage);
    } on ReminderApiFailure catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Unable to update the reminder. Try again.');
    } finally {
      if (mounted) {
        setState(() => _busyReminderIds.remove(reminder.occurrenceId));
      }
    }
  }

  Future<void> _showReminderDetails(ElderlyReminder reminder) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PatientReminderDetailPage(
          reminder: reminder,
          onComplete: () => _completeReminder(reminder),
          onSnooze: () => _snoozeReminder(reminder),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alera')),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TickerMode(
            enabled: _selectedIndex == 0,
            child: ElderlyHomePage(
              state: ElderlyHomeViewState(
                heartRate: heartRateData,
                spo2: spo2Data,
                steps: stepsData,
                sleep: sleepData,
                deviceStatus: deviceStatusData,
                reminders: reminders,
                remindersLoading: remindersLoading,
                remindersError: remindersError,
              ),
              uploadQueueService: uploadQueueService,
              onReminderTap: _showReminderDetails,
              onRetryReminders: _loadReminders,
              onOpenDeviceStatus: () {
                if (_selectedIndex == 2) return;
                setState(() => _selectedIndex = 2);
              },
            ),
          ),
          TickerMode(
            enabled: _selectedIndex == 1,
            child: ElderlyRemindersPage(
              isLoading: remindersLoading,
              errorMessage: remindersError,
              reminders: reminders,
              busyOccurrenceIds: _busyReminderIds,
              onOpen: _showReminderDetails,
              onComplete: _completeReminder,
              onSnooze: _snoozeReminder,
              onRetry: _loadReminders,
            ),
          ),
          TickerMode(
            enabled: _selectedIndex == 2,
            child: ElderlyMorePage(
              deviceStatusData: deviceStatusData,
              onSignOut: widget.onSignOut,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          elevation: 0,
          height: 68,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            if (_selectedIndex == index) return;
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'Reminders',
            ),
            NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
          ],
        ),
      ),
    );
  }
}
