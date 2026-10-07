import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../data/reminder_timeline_controller.dart';
import '../../domain/reminder_event.dart';
import '../reminder_event_text.dart';

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
      builder: (context, _) => Column(
        key: const Key('reminder-timeline'),
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
    final titleSize = elderly ? 20.0 : 15.0;
    final bodySize = elderly ? 17.0 : 13.0;
    final secondary = TextStyle(
      fontSize: bodySize,
      color: AleraColors.textSecondary,
    );
    return IntrinsicHeight(
      key: Key('reminder-event-${event.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AleraColors.selected,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AleraColors.divider),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: elderly ? 20 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: AleraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [reminderEventWhen(event.occurredAt), ?actor].join(' · '),
                    style: secondary,
                  ),
                  for (final line in details) Text(line, style: secondary),
                  if (event.note case final note?)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: bodySize,
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
