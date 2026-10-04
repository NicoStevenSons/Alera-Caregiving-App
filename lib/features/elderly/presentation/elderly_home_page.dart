import 'package:flutter/material.dart';

import '../../../Services/upload_queue_service.dart';
import '../domain/elderly_home_view_state.dart';
import '../domain/models/elderly_reminder.dart';
import 'widgets/heart_rate_display.dart';
import 'widgets/sleep_display.dart';
import 'widgets/spo2_display.dart';
import 'widgets/steps_display.dart';

class ElderlyHomePage extends StatelessWidget {
  const ElderlyHomePage({
    super.key,
    required this.state,
    required this.uploadQueueService,
    this.onRequestHelp,
    this.onReminderTap,
    this.onRetryReminders,
  });

  final ElderlyHomeViewState state;
  final UploadQueueService uploadQueueService;
  final VoidCallback? onRequestHelp;
  final ValueChanged<ElderlyReminder>? onReminderTap;
  final VoidCallback? onRetryReminders;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('elderly-home'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _MonitoringStatusCard(state: state.monitoringState),
        const SizedBox(height: 16),
        Semantics(
          label: 'Request help from your caregiver',
          button: true,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              key: const Key('elderly-request-help'),
              onPressed: onRequestHelp,
              icon: const Icon(Icons.sos_rounded),
              label: const Text('Request Help'),
            ),
          ),
        ),
        if (onRequestHelp == null) ...[
          const SizedBox(height: 8),
          Text(
            'Help requests will be available soon.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: HeartRateDisplay(
                heartRateData: state.heartRate,
                uploadQueueService: uploadQueueService,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SpO2Display(
                spo2Data: state.spo2,
                uploadQueueService: uploadQueueService,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StepsDisplay(stepsData: state.steps),
        const SizedBox(height: 16),
        SleepDisplay(sleepData: state.sleep),
        const SizedBox(height: 16),
        _NextReminderCard(
          loading: state.remindersLoading,
          errorMessage: state.remindersError,
          reminder: state.nextReminder,
          onTap: onReminderTap,
          onRetry: onRetryReminders,
        ),
      ],
    );
  }
}

class _MonitoringStatusCard extends StatelessWidget {
  const _MonitoringStatusCard({required this.state});

  final ElderlyMonitoringState state;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String message) = switch (state) {
      ElderlyMonitoringState.connected => (
        Icons.check_circle_rounded,
        'Monitoring active',
        'Your smartwatch is connected.',
      ),
      ElderlyMonitoringState.disconnected => (
        Icons.link_off_rounded,
        'Smartwatch disconnected',
        'Open More to check your device connection.',
      ),
      ElderlyMonitoringState.notWorn => (
        Icons.watch_off_rounded,
        'Smartwatch not worn',
        'Wear your smartwatch to continue monitoring.',
      ),
      ElderlyMonitoringState.waitingForWatch => (
        Icons.watch_rounded,
        'Waiting for smartwatch',
        'Health readings will appear when your watch connects.',
      ),
    };

    return Card(
      key: const Key('elderly-monitoring-status'),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(message),
      ),
    );
  }
}

class _NextReminderCard extends StatelessWidget {
  const _NextReminderCard({
    required this.loading,
    required this.errorMessage,
    required this.reminder,
    required this.onTap,
    required this.onRetry,
  });

  final bool loading;
  final String? errorMessage;
  final ElderlyReminder? reminder;
  final ValueChanged<ElderlyReminder>? onTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final item = reminder;

    if (loading) {
      return const Card(
        key: Key('elderly-next-reminder-loading'),
        child: ListTile(
          leading: Icon(Icons.schedule_rounded),
          title: Text('Loading next reminder…'),
        ),
      );
    }

    if (errorMessage != null) {
      return Card(
        key: const Key('elderly-next-reminder-error'),
        child: ListTile(
          leading: const Icon(Icons.cloud_off_rounded),
          title: const Text('Unable to load reminders'),
          subtitle: Text(errorMessage!),
          trailing: TextButton(
            key: const Key('elderly-retry-reminders'),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      );
    }

    if (item == null) {
      return const Card(
        key: Key('elderly-next-reminder-empty'),
        child: ListTile(
          leading: Icon(Icons.event_available_rounded),
          title: Text('No upcoming reminders'),
        ),
      );
    }

    return Card(
      key: const Key('elderly-next-reminder'),
      child: ListTile(
        onTap: onTap == null ? null : () => onTap!(item),
        leading: const Icon(Icons.schedule_rounded),
        title: Text(item.title),
        subtitle: Text(_time(item.scheduledAt)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
