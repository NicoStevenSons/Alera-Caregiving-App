import 'package:flutter/material.dart';

import '../Services/watch_payload_service.dart';
import '../Services/health_event_api_service.dart';
import '../Services/upload_queue_service.dart';
import '../Services/fifo_upload_service.dart';
import '../Services/watch_listener_controller.dart';

import '../config/app_config.dart';

import '../models/heart_rate_data.dart';
import '../models/spo2_data.dart';
import '../models/steps_data.dart';
import '../models/device_status_data.dart';
import '../models/sleep_data.dart';

import '../features/elderly/presentation/widgets/device_status_dialog.dart';
import '../features/elderly/presentation/widgets/sleep_display.dart';
import '../features/elderly/presentation/widgets/heart_rate_display.dart';
import '../features/elderly/presentation/widgets/spo2_display.dart';
import '../features/elderly/presentation/widgets/steps_display.dart';
import '../features/elderly/domain/models/elderly_reminder.dart';
import '../features/elderly/data/api/elderly_reminder_supabase_service.dart';
import '../features/elderly/services/reminder_notification_service.dart';
import '../features/elderly/presentation/widgets/elderly_reminders_list.dart';
import '../features/elderly/data/local/reminder_local_service.dart';
import '../features/elderly/data/sync/reminder_action_sync_service.dart';




class ElderlyInterface extends StatefulWidget {
  const ElderlyInterface({super.key});

  @override
  State<ElderlyInterface> createState() => _ElderlyInterfaceState();
}

class _ElderlyInterfaceState extends State<ElderlyInterface>
    with WidgetsBindingObserver {

  final WatchPayloadService watchPayloadService = WatchPayloadService();

  final HealthEventApiService healthEventApiService = HealthEventApiService(
    baseUrl: AppConfig.backendBaseUrl,
    patientId: AppConfig.testPatientId,
  );

  final UploadQueueService uploadQueueService = UploadQueueService();

  final ReminderLocalService reminderLocalService = ReminderLocalService();

  final ElderlyReminderSupabaseService reminderService = ElderlyReminderSupabaseService();

  

  List<ElderlyReminder> reminders = [];

  bool remindersLoading = true;

  late final FifoUploadService fifoUploadService;

  late final WatchListenerController watchListenerController;

  late final ReminderActionSyncService reminderActionSyncService;

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

    WidgetsBinding.instance.addObserver(this);

    fifoUploadService = FifoUploadService(
      uploadQueueService: uploadQueueService,
      healthEventApiService: healthEventApiService,
    );

    reminderActionSyncService =
      ReminderActionSyncService(
      localService: reminderLocalService,
    );

    watchListenerController = WatchListenerController(
      watchPayloadService: watchPayloadService,
      uploadQueueService: uploadQueueService,
      healthEventApiService: healthEventApiService,
      fifoUploadService: fifoUploadService,

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
        if (!mounted) {
          return;
        }

        debugPrint(
          'MAIN RECEIVED DEVICE STATUS: '
          'battery=${data.batteryPercent}, '
          'device=${data.deviceName}, '
          'model=${data.deviceModel}, '
          'connected=${data.connectedToPhone}, '
          'phone=${data.connectedPhoneName}',
        );

        setState(() {
          deviceStatusData = deviceStatusData.copyWith(
            batteryPercent: data.batteryPercent,
            deviceName: data.deviceName,
            deviceModel: data.deviceModel,
            connectedToPhone: data.connectedToPhone,
            connectedPhoneName: data.connectedPhoneName,
            measuredAt: data.measuredAt,
          );
        });
      },

      onSleepUpdated: (SleepData data) {
        if (!mounted) return;

        setState(() {
          sleepData = data;
        });
      },
    );

    _loadReminders();

    _syncPendingReminderActions();

    watchListenerController.start();

    _processPendingQueue();
  }

  Future<void> _processPendingQueue() async {
    if (!AppConfig.enableBackend) {
      return;
    }

    debugPrint('Checking pending upload queue...');

    await fifoUploadService.processQueue();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed. Processing pending queue.');

      _processPendingQueue();

      _syncPendingReminderActions();
    }
  }

  Future<void> _scheduleReminderIfNeeded(
  ElderlyReminder reminder,
) async {
  final bool canSchedule =
      reminder.status == 'UPCOMING' ||
      reminder.status == 'SNOOZED';

  final bool isFuture =
      reminder.dueAt.isAfter(DateTime.now());

  if (!canSchedule || !isFuture) {
    debugPrint(
      'Skipping alarm for ${reminder.title}: '
      'status=${reminder.status}, '
      'dueAt=${reminder.dueAt}',
    );
    return;
  }

  await ReminderNotificationService.instance
      .scheduleReminder(reminder);
}

  Future<void> _loadReminders() async {
  try {
    debugPrint('Loading reminders from Supabase...');

    final result =
        await reminderService.getRemindersForPatient(
      AppConfig.testPatientId,
    );

    debugPrint(
      'Loaded ${result.length} reminders from Supabase',
    );

    //save em latest online data locally.
    await reminderLocalService.saveReminders(
      result,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      reminders = result;
      remindersLoading = false;
    });

   for (final reminder in result) {
  await _scheduleReminderIfNeeded(reminder);
}


  } catch (error) {
    debugPrint(
      'Supabase reminder load failed: $error',
    );

    debugPrint(
      'Trying local reminder cache...',
    );

    try {
      final localReminders =
          await reminderLocalService.getReminders(
        AppConfig.testPatientId,
      );

      debugPrint(
        'Loaded ${localReminders.length} reminders from SQLite',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        reminders = localReminders;
        remindersLoading = false;
      });

      for (final reminder in localReminders) {
  await _scheduleReminderIfNeeded(reminder);
      } 
    } catch (localError) {
      debugPrint(
        'Local reminder load failed: $localError',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        reminders = [];
        remindersLoading = false;
      });
    }
  }
}

  Future<void> _completeReminder(
  ElderlyReminder reminder,
) async {
  await reminderLocalService.completeReminder(
    reminder,
  );

  await ReminderNotificationService.instance
      .cancelReminder(reminder);

  final updated =
      await reminderLocalService.getReminders(
    AppConfig.testPatientId,
  );

  if (!mounted) {
    return;
  }

  setState(() {
    reminders = updated;
  });

  debugPrint(
    'Reminder completed locally: ${reminder.title}',
  );
}

  Future<void> _snoozeReminder(
  ElderlyReminder reminder,
) async {
  final DateTime newDueAt =
      await reminderLocalService.snoozeReminder(
    reminder,
  );

  await ReminderNotificationService.instance
      .cancelReminder(reminder);

  final updated =
      await reminderLocalService.getReminders(
    AppConfig.testPatientId,
  );

  if (!mounted) {
    return;
  }

  setState(() {
    reminders = updated;
  });

  final ElderlyReminder? updatedReminder =
      await reminderLocalService.getReminder(
    reminder.occurrenceId,
  );

  if (updatedReminder != null) {
    await ReminderNotificationService.instance
        .scheduleReminder(updatedReminder);
  }

  debugPrint(
    'Reminder snoozed until $newDueAt',
  );
}

Future<void> _syncPendingReminderActions() async {
  try {
    final String userId =
        await reminderService.getPatientUserId(
      AppConfig.testPatientId,
    );

    await reminderActionSyncService
        .syncPendingActions(
      performedByUserId: userId,
    );
  } catch (error) {
    debugPrint(
      'Reminder action sync skipped/failed: $error',
    );
  }
}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    watchPayloadService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,

          title: const Text('Alera'),

          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Vitals'),
              Tab(text: 'Reminders'),
            ],
          ),

          actions: [
            IconButton(
              icon: Icon(
                deviceStatusData.connectedToPhone == true
                    ? Icons.watch
                    : Icons.watch_off,
              ),

              onPressed: () {
                showDeviceStatusDialog(
                  context: context,
                  deviceStatusData: deviceStatusData,
                );
              },
            ),

            const SizedBox(width: 12),
          ],
        ),

        body: TabBarView(
          children: [
            // VITALS TAB
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  Row(
                    children: [

                      Expanded(
                        child:
                            HeartRateDisplay(
                              heartRateData: heartRateData,
                              uploadQueueService:
                              uploadQueueService,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child:
                        SpO2Display(
                          spo2Data: spo2Data,
                          uploadQueueService:
                          uploadQueueService,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  StepsDisplay(stepsData: stepsData),

                  const SizedBox(height: 16),

                  SleepDisplay(sleepData: sleepData),

                  const SizedBox(height: 16),

                ],
              ),
            ),

            // REMINDERS TAB
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ElderlyRemindersList(
                        isLoading: remindersLoading,
                        reminders: reminders,
                        onComplete: _completeReminder,
                        onSnooze: _snoozeReminder,
),
                ],
              ),
            )
    
          ],
        ),
      ),
    );
  }
}
