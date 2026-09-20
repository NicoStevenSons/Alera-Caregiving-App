import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_button.dart';
import '../../../../../design_system/widgets/alera_card.dart';

/// Step title + optional helper line, at the top of each Add Patient screen
/// (Figma: "Personal Information" / "Fill in information about your
/// patient.").
class SetupHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool centered;
  final double bottomSpacing;

  const SetupHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.centered = false,
    this.bottomSpacing = 20,
  });

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: align,
            style: AleraTypography.sectionTitle.copyWith(fontSize: 18),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: align,
              style: AleraTypography.body.copyWith(fontSize: 13, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

/// Selectable radio-style option tile (Figma: "Use Alera defaults" / "Set
/// custom ranges"). Built on [AleraCard] rather than a bespoke container.
class SetupOptionCard extends StatelessWidget {
  final bool selected;
  final String title;
  final List<String> lines;
  final VoidCallback onTap;

  const SetupOptionCard({
    super.key,
    required this.selected,
    required this.title,
    required this.lines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      onTap: onTap,
      color: selected ? AleraColors.surfaceTint : AleraColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: _RadioDot(selected: selected),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AleraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                for (final line in lines)
                  Text(
                    line,
                    style: AleraTypography.body.copyWith(
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AleraColors.primary : AleraColors.textSecondary,
          width: selected ? 2 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AleraColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

/// Back / Continue pair pinned under a step's fields (Figma bottom bar).
class SetupButtonRow extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final String backLabel;

  const SetupButtonRow({
    super.key,
    required this.onBack,
    required this.onNext,
    this.nextLabel = 'Continue',
    this.backLabel = 'Back',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AleraButton(
            label: backLabel,
            variant: AleraButtonVariant.lightPill,
            height: 44,
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AleraButton(
            label: nextLabel,
            variant: AleraButtonVariant.pill,
            height: 44,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

/// A label/value pair inside a review card (Figma: "Full name" / "Zachary
/// Legaria").
class SetupLabeledValue extends StatelessWidget {
  final String label;
  final String? value;
  final String emptyText;

  const SetupLabeledValue({
    super.key,
    required this.label,
    required this.value,
    this.emptyText = 'Not provided',
  });

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AleraTypography.body.copyWith(fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          has ? value!.trim() : emptyText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: has ? FontWeight.w500 : FontWeight.w400,
            color: has ? AleraColors.textPrimary : AleraColors.fieldHint,
          ),
        ),
      ],
    );
  }
}

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Jan 12, 1952"
String formatBirthdate(DateTime value) =>
    '${_months[value.month - 1]} ${value.day}, ${value.year}';

/// "Sep 13 at 1:34 PM" (local time)
String formatAccessExpiry(DateTime value) {
  final local = value.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${_months[local.month - 1]} ${local.day} at $hour12:$minute $suffix';
}
