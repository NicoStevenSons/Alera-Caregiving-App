import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import 'trend_date_format.dart';

/// The chart card's own header: a title ("Heart Rate Trend"), the date
/// range it's showing, and a dropdown to change that range - replacing the
/// old page-level 24H/7D/30D button row.
class VitalTrendRangeHeader extends StatelessWidget {
  final String title;
  final DateTime fromDate;
  final DateTime toDate;
  final String selectedLabel;
  final List<String> rangeLabels;
  final ValueChanged<String> onRangeSelected;

  const VitalTrendRangeHeader({
    super.key,
    required this.title,
    required this.fromDate,
    required this.toDate,
    required this.selectedLabel,
    required this.rangeLabels,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AleraTypography.sectionTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatTrendLongDate(fromDate)} – '
                '${formatTrendLongDate(toDate)}',
                style: AleraTypography.body.copyWith(
                  fontSize: 11,
                  color: AleraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _RangeDropdown(
          selectedLabel: selectedLabel,
          rangeLabels: rangeLabels,
          onRangeSelected: onRangeSelected,
        ),
      ],
    );
  }
}

class _RangeDropdown extends StatelessWidget {
  final String selectedLabel;
  final List<String> rangeLabels;
  final ValueChanged<String> onRangeSelected;

  const _RangeDropdown({
    required this.selectedLabel,
    required this.rangeLabels,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const Key('trend-range-dropdown'),
      initialValue: selectedLabel,
      onSelected: onRangeSelected,
      tooltip: 'Change date range',
      itemBuilder: (context) => [
        for (final label in rangeLabels)
          PopupMenuItem<String>(
            value: label,
            child: Row(
              children: [
                if (label == selectedLabel)
                  const Icon(Icons.check, size: 16, color: AleraColors.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AleraColors.primarySoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLabel,
              style: AleraTypography.label.copyWith(
                color: AleraColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AleraColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
