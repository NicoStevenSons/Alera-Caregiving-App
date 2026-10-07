import 'package:flutter/material.dart';

import '../../domain/models/elderly_reminder.dart';
import 'elderly_reminder_card.dart';
import 'elderly_widgets.dart';

class ElderlyRemindersList extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final List<ElderlyReminder> reminders;
  final Future<void> Function(ElderlyReminder reminder)? onComplete;
  final Future<void> Function(ElderlyReminder reminder)? onSnooze;
  final Set<String> busyOccurrenceIds;
  final void Function(ElderlyReminder reminder)? onTap;
  final VoidCallback? onRetry;

  const ElderlyRemindersList({
    super.key,
    required this.isLoading,
    this.errorMessage,
    required this.reminders,
    this.onComplete,
    this.onSnooze,
    this.busyOccurrenceIds = const <String>{},
    this.onTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        key: Key('elderly-reminders-loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        key: const Key('elderly-reminders-error'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Unable to load reminders',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const Key('elderly-reminders-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (reminders.isEmpty) {
      return const Center(
        key: Key('elderly-reminders-empty'),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_rounded, size: 40),
              SizedBox(height: 12),
              Text('No reminders right now'),
            ],
          ),
        ),
      );
    }

    const Set<String> finished = {'COMPLETED', 'COMPLETED_LATE', 'CANCELED'};
    final List<ElderlyReminder> open = reminders
        .where((r) => !finished.contains(r.status))
        .toList();
    final List<ElderlyReminder> done = reminders
        .where((r) => finished.contains(r.status))
        .toList();
    final List<ElderlyReminder> missed = open
        .where((r) => r.status == 'MISSED')
        .toList();
    final List<ElderlyReminder> active = open
        .where((r) => r.status != 'MISSED')
        .toList();

    // Only the single most urgent reminder gets action buttons; everything
    // else is a compact row that opens the full card.
    ElderlyReminder? primary;
    for (final r in active) {
      if (r.status == 'DUE') {
        primary = r;
        break;
      }
    }
    primary ??= active.isEmpty ? null : active.first;
    final List<ElderlyReminder> later = active
        .where((r) => r != primary)
        .toList();

    Widget row(ElderlyReminder r) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElderlyDoneReminderRow(reminder: r, onTap: () => onTap?.call(r)),
    );

    final List<Widget> children = [];
    void section(String title, List<Widget> items) {
      if (items.isEmpty) return;
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      children
        ..add(ElderlySectionTitle(title))
        ..add(const SizedBox(height: 12))
        ..addAll(items);
    }

    if (primary != null) {
      final ElderlyReminder p = primary!;
      section(p.status == 'DUE' ? 'Due now' : 'Up next', [
        ElderlyReminderCard(
          reminder: p,
          busy: busyOccurrenceIds.contains(p.occurrenceId),
          onTap: () => onTap?.call(p),
          onComplete: () => onComplete?.call(p),
          onSnooze: () => onSnooze?.call(p),
        ),
      ]);
    }
    section('Missed', missed.map(row).toList());
    section('Later today', later.map(row).toList());
    section('Done', done.map(row).toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
