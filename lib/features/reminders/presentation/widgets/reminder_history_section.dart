import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../data/reminder_timeline_controller.dart';
import '../../domain/reminder_event.dart';
import '../reminder_event_text.dart';
import '../reminder_formatters.dart';

/// The chronological history of one reminder occurrence (oldest first), with
/// loading, empty, retryable-error and "Load more" states. Used by the
/// caregiver detail page and, with [elderly] set, by the patient's detail
/// page (bigger text, friendlier wording, no technical terms).
class ReminderHistorySection extends StatelessWidget {
  const ReminderHistorySection({
    super.key,
    required this.controller,
    this.elderly = false,
  });

  final ReminderTimelineController controller;
  final bool elderly;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => AleraCard(
        key: const Key('reminder-timeline'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                elderly ? 'History' : 'Timeline',
                key: const Key('reminder-timeline-title'),
                style: elderly
                    ? const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                    : AleraTypography.sectionTitle,
              ),
              SizedBox(height: elderly ? 14 : 10),
              _body(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final fontSize = elderly ? 18.0 : 14.0;
    if (controller.errorMessage case final message?) {
      return _Message(
        key: const Key('reminder-timeline-error'),
        text: elderly ? 'We couldn’t load the history.' : message,
        fontSize: fontSize,
        action: controller.notFound
            ? null
            : TextButton(
                key: const Key('reminder-timeline-retry'),
                onPressed: controller.load,
                child: Text(
                  elderly ? 'Try again' : 'Retry',
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
      );
    }
    if (controller.loading && controller.events.isEmpty) {
      return const Padding(
        key: Key('reminder-timeline-loading'),
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.isEmpty) {
      return _Message(
        key: const Key('reminder-timeline-empty'),
        text: elderly
            ? 'Nothing has happened with this reminder yet.'
            : 'No activity yet.',
        fontSize: fontSize,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < controller.events.length; i++)
          _EventRow(
            event: controller.events[i],
            elderly: elderly,
            isLast: i == controller.events.length - 1,
          ),
        if (controller.loadMoreError case final message?)
          _Message(
            key: const Key('reminder-timeline-load-more-error'),
            text: elderly ? 'We couldn’t load more.' : message,
            fontSize: fontSize,
          ),
        if (controller.hasMore)
          Align(
            alignment: Alignment.centerLeft,
            child: controller.loadingMore
                ? const Padding(
                    key: Key('reminder-timeline-loading-more'),
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    key: const Key('reminder-timeline-load-more'),
                    onPressed: controller.loadMore,
                    child: Text(
                      elderly ? 'Show more' : 'Load more',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.text,
    required this.fontSize,
    this.action,
  });

  final String text;
  final double fontSize;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: AleraColors.textSecondary,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}

/// One timeline entry, laid out like the alert detail timeline: dot with a
/// connector, the time on the left, then a bold title with a lighter line.
class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.elderly,
    required this.isLast,
  });

  final ReminderEvent event;
  final bool elderly;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final label = elderly ? elderlyEventLabel(event) : caregiverEventLabel(event);
    final actor = elderly ? elderlyEventActor(event) : caregiverEventActor(event);
    final details = elderly
        ? elderlyEventDetails(event)
        : caregiverEventDetails(event);
    final local = event.occurredAt.toLocal();
    final titleSize = elderly ? 19.0 : 14.0;
    final bodySize = elderly ? 16.0 : 12.0;
    final secondary = AleraTypography.body.copyWith(fontSize: bodySize);
    const accent = AleraColors.selected;
    return IntrinsicHeight(
      key: Key('reminder-event-${event.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              const Icon(Icons.circle, color: accent, size: 16),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: accent.withValues(alpha: 0.20),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: elderly ? 92 : 72,
            child: Text(
              reminderClock(local),
              style: AleraTypography.body.copyWith(
                fontSize: elderly ? 16 : null,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: elderly ? 18 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AleraTypography.label.copyWith(
                      fontSize: titleSize,
                      color: AleraColors.textPrimary,
                    ),
                  ),
                  Text(
                    [reminderShortDate(local), ?actor].join(' · '),
                    style: secondary,
                  ),
                  for (final line in details) Text(line, style: secondary),
                  if (event.note case final note?)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        note,
                        style: secondary.copyWith(
                          color: AleraColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
