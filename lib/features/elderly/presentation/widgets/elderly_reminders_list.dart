import 'package:flutter/material.dart';

import '../../domain/models/elderly_reminder.dart';
import 'elderly_reminder_card.dart';
import '../../../../design_system/alera_colors.dart';
import 'elderly_widgets.dart';

class ElderlyRemindersList extends StatefulWidget {
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

  static const int collapsedCount = 3;

  @override
  State<ElderlyRemindersList> createState() => _ElderlyRemindersListState();
}

class _ElderlyRemindersListState extends State<ElderlyRemindersList> {
  final Set<String> _expanded = <String>{};

  bool get isLoading => widget.isLoading;
  String? get errorMessage => widget.errorMessage;
  List<ElderlyReminder> get reminders => widget.reminders;
  Set<String> get busyOccurrenceIds => widget.busyOccurrenceIds;
  void Function(ElderlyReminder reminder)? get onTap => widget.onTap;
  Future<void> Function(ElderlyReminder reminder)? get onComplete =>
      widget.onComplete;
  Future<void> Function(ElderlyReminder reminder)? get onSnooze =>
      widget.onSnooze;
  VoidCallback? get onRetry => widget.onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        key: Key('elderly-reminders-loading'),
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return KeyedSubtree(
        key: const Key('elderly-reminders-error'),
        child: ElderlyStateMessage(
          icon: Icons.cloud_off_rounded,
          color: const Color(0xFFE04C5D),
          title: 'Unable to load reminders',
          message: errorMessage,
          action: FilledButton.icon(
            key: const Key('elderly-reminders-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
      );
    }

    if (reminders.isEmpty) {
      return const KeyedSubtree(
        key: Key('elderly-reminders-empty'),
        child: ElderlyStateMessage(
          icon: Icons.event_available_rounded,
          title: 'No reminders right now',
          message: 'When your caregiver adds a reminder, it will show up here.',
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
    void section(String title, List<ElderlyReminder> items) {
      if (items.isEmpty) return;
      final bool expanded = _expanded.contains(title);
      final bool capped =
          items.length > ElderlyRemindersList.collapsedCount;
      final List<ElderlyReminder> shown = capped && !expanded
          ? items.take(ElderlyRemindersList.collapsedCount).toList()
          : items;
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      children
        ..add(
          Row(
            children: [
              Expanded(child: ElderlySectionTitle(title)),
              if (capped)
                Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AleraColors.textSecondary,
                  ),
                ),
            ],
          ),
        )
        ..add(const SizedBox(height: 12))
        ..addAll(shown.map(row));
      if (capped) {
        children.add(
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: Key('elderly-reminders-toggle-$title'),
              onPressed: () => setState(() {
                expanded ? _expanded.remove(title) : _expanded.add(title);
              }),
              child: Text(
                expanded ? 'Show less' : 'Show all ${items.length}',
              ),
            ),
          ),
        );
      }
    }

    if (primary != null) {
      final ElderlyReminder p = primary!;
      children
        ..add(ElderlySectionTitle(p.status == 'DUE' ? 'Due now' : 'Up next'))
        ..add(const SizedBox(height: 12))
        ..add(
          ElderlyReminderCard(
            reminder: p,
            busy: busyOccurrenceIds.contains(p.occurrenceId),
            onTap: () => onTap?.call(p),
            onComplete: () => onComplete?.call(p),
            onSnooze: () => onSnooze?.call(p),
          ),
        );
    }
    section('Missed', missed);
    section('Later today', later);
    section('Done', done);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
