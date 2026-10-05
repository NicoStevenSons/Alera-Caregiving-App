import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_typography.dart';
import '../../../design_system/widgets/alera_card.dart';
import '../../../design_system/widgets/alera_pill.dart';
import '../../../design_system/widgets/alera_svg_icon.dart';
import '../data/reminder_controller.dart';
import '../domain/reminder_models.dart';
import 'reminder_action_runner.dart';
import 'reminder_formatters.dart';

/// Recurring reminder templates (and archived ones) for the patient whose
/// reminders are on the main page. Kept off the main timeline.
class ReminderSchedulesPage extends StatelessWidget {
  const ReminderSchedulesPage({
    super.key,
    required this.controller,
    this.patientName,
  });

  final ReminderController controller;
  final String? patientName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AleraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 44,
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left, size: 28),
          color: const Color(0xFFB4AEC2),
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final templates = controller.templates;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                'Manage schedules',
                style: AleraTypography.pageTitle.copyWith(fontSize: 22),
              ),
              if (patientName != null) ...[
                const SizedBox(height: 4),
                Text(
                  '$patientName’s recurring reminders',
                  style: AleraTypography.body.copyWith(
                    color: AleraColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (templates.isEmpty)
                const Padding(
                  key: Key('reminder-templates-empty'),
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_repeat_outlined,
                          size: 48,
                          color: Color(0xFFCFC7E8),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No reminder schedules yet',
                          style: TextStyle(
                            color: Color(0xFFA69BD2),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final template in templates) ...[
                  _ScheduleCard(
                    template: template,
                    busy: controller.isTemplateBusy(template.id),
                    onArchive:
                        template.status == ReminderTemplateStatus.archived
                        ? null
                        : () => _archive(context, template),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _archive(BuildContext context, ReminderTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive schedule?'),
        content: Text(
          'Future occurrences for “${template.title}” will be canceled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await runReminderAction(
      context,
      () => controller.archiveTemplate(template.id),
      success: 'Schedule archived.',
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.template,
    required this.busy,
    required this.onArchive,
  });

  final ReminderTemplate template;
  final bool busy;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final archived = template.status == ReminderTemplateStatus.archived;
    final repeat = reminderRepeatLabel(template);
    return AleraCard(
      key: ValueKey('reminder-template-${template.id}'),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AleraColors.primarySoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Opacity(
                opacity: archived ? 0.5 : 1,
                child: AleraSvgIcon(
                  assetPath: reminderCategoryAsset(template.category),
                  width: 28,
                  height: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AleraTypography.sectionTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Starts ${template.startDate} at '
                  '${template.startTime.substring(0, 5)}'
                  '${repeat == null ? '' : ' • $repeat'}',
                  style: AleraTypography.body.copyWith(
                    fontSize: 12,
                    color: AleraColors.textSecondary,
                  ),
                ),
                if (archived) ...[
                  const SizedBox(height: 6),
                  const AleraPill(
                    label: 'Archived',
                    variant: AleraPillVariant.label,
                  ),
                ],
              ],
            ),
          ),
          if (busy)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (onArchive != null)
            IconButton(
              key: ValueKey('reminder-archive-${template.id}'),
              tooltip: 'Archive schedule',
              color: AleraColors.textSecondary,
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined),
            ),
        ],
      ),
    );
  }
}
