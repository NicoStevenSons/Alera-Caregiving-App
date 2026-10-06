import 'package:flutter/material.dart';

import '../../../Services/upload_queue_service.dart';
import '../data/elderly_help_request_controller.dart';
import '../domain/elderly_home_view_state.dart';
import '../../help_requests/domain/help_request.dart';
import '../domain/models/elderly_reminder.dart';
import '../../../design_system/alera_colors.dart';
import 'elderly_reminder_style.dart';
import 'widgets/elderly_help_request_card.dart';
import 'widgets/heart_rate_display.dart';
import 'widgets/sleep_display.dart';
import 'widgets/spo2_display.dart';
import 'widgets/steps_display.dart';

class ElderlyHomePage extends StatelessWidget {
  const ElderlyHomePage({
    super.key,
    required this.state,
    required this.uploadQueueService,
    this.helpRequestState = ElderlyHelpRequestState.available,
    this.activeHelpRequest,
    this.helpRequestError,
    this.onRequestHelp,
    this.onRetryHelpRequest,
    this.onReminderTap,
    this.onRetryReminders,
    this.onOpenDeviceStatus,
  });

  final ElderlyHomeViewState state;
  final UploadQueueService uploadQueueService;
  final ElderlyHelpRequestState helpRequestState;
  final HelpRequestRecord? activeHelpRequest;
  final String? helpRequestError;
  final VoidCallback? onRequestHelp;
  final VoidCallback? onRetryHelpRequest;
  final ValueChanged<ElderlyReminder>? onReminderTap;
  final VoidCallback? onRetryReminders;
  final VoidCallback? onOpenDeviceStatus;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('elderly-home'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _MonitoringStatusCard(
          state: state.monitoringState,
          onOpenDeviceStatus: onOpenDeviceStatus,
        ),
        const SizedBox(height: 16),
        _NextReminderCard(
          loading: state.remindersLoading,
          errorMessage: state.remindersError,
          reminder: state.nextReminder,
          onTap: onReminderTap,
          onRetry: onRetryReminders,
        ),
        const SizedBox(height: 16),
        ElderlyHelpRequestCard(
          state: helpRequestState,
          activeRequest: activeHelpRequest,
          errorMessage: helpRequestError,
          onRequestHelp: onRequestHelp,
          onRetry: onRetryHelpRequest,
        ),
        const SizedBox(height: 28),
        const _SectionTitle('Today\'s health'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: HeartRateDisplay(
                heartRateData: state.heartRate,
                uploadQueueService: uploadQueueService,
              ),
            ),
            const SizedBox(width: 12),
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
      ],
    );
  }
}

class _MonitoringStatusCard extends StatelessWidget {
  const _MonitoringStatusCard({
    required this.state,
    required this.onOpenDeviceStatus,
  });

  final ElderlyMonitoringState state;
  final VoidCallback? onOpenDeviceStatus;

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

    final actionable =
        state != ElderlyMonitoringState.connected && onOpenDeviceStatus != null;

    final Color color = switch (state) {
      ElderlyMonitoringState.connected => const Color(0xFF05A869),
      ElderlyMonitoringState.waitingForWatch => AleraColors.information,
      _ => const Color(0xFFD99A00),
    };

    return Card(
      key: const Key('elderly-monitoring-status'),
      child: ListTile(
        onTap: actionable ? onOpenDeviceStatus : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title),
        subtitle: Text(message),
        trailing: actionable ? const Icon(Icons.chevron_right_rounded) : null,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AleraColors.textPrimary,
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

    final ElderlyReminderStyle style = ElderlyReminderStyle.forCategory(
      item.category,
    );

    return Card(
      key: const Key('elderly-next-reminder'),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap == null ? null : () => onTap!(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next reminder',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AleraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AleraColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _time(item.scheduledAt),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: style.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: AleraColors.textSecondary,
              ),
            ],
          ),
        ),
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
