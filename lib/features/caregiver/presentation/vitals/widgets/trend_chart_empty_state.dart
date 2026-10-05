import 'package:flutter/material.dart';

/// Sits in the chart's spot, inside the same card as its title/date/range
/// dropdown, when a period has no readings - rather than replacing the
/// whole card (which used to take the range dropdown down with it, leaving
/// no way to try a different period). The dropdown above this stays put,
/// so switching ranges from an empty period always works.
///
/// Styled to match the "No active alerts" empty state on the alerts page
/// (same muted greys), so empty states read the same across the app.
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: Color(0xFFCFC7E8),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFA69BD2),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB5AADB), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
