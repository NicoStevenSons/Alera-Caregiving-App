import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';

/// Sits in the chart's spot, inside the same card as its title/date/range
/// dropdown, when a period has no readings - rather than replacing the
/// whole card (which used to take the range dropdown down with it, leaving
/// no way to try a different period). The dropdown above this stays put,
/// so switching ranges from an empty period always works.
class TrendChartEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const TrendChartEmptyState({
    super.key,
    this.title = 'No readings in this period',
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AleraColors.primarySoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.show_chart_rounded,
                size: 26,
                color: AleraColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AleraTypography.sectionTitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AleraTypography.body.copyWith(
                  fontSize: 12,
                  color: AleraColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
