import 'package:flutter/material.dart';

import '../../../../../design_system/widgets/alera_section_card.dart';
import '../../../domain/models/caregiver_alert.dart';
import '../../widgets/caregiver_alert_card.dart';

class PatientAlertHistory extends StatefulWidget {
  final List<CaregiverAlert> alerts;
  final VoidCallback onViewAll;
  final ValueChanged<CaregiverAlert> onAlertTap;
  final ValueChanged<CaregiverAlert>? onMarkAsSeen;

  const PatientAlertHistory({
    super.key,
    required this.alerts,
    required this.onViewAll,
    required this.onAlertTap,
    this.onMarkAsSeen,
  });

  @override
  State<PatientAlertHistory> createState() => _PatientAlertHistoryState();
}

class _PatientAlertHistoryState extends State<PatientAlertHistory> {
  final Set<String> _expandedAlertIds = <String>{};

  void _toggle(String id) {
    setState(() {
      if (!_expandedAlertIds.add(id)) _expandedAlertIds.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<CaregiverAlert> recentAlerts = [...widget.alerts]
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    final List<CaregiverAlert> visibleAlerts = recentAlerts.take(3).toList();

    return AleraSectionCard(
      title: 'Alert History',
      actionLabel: 'View All Alerts',
      onActionPressed: widget.onViewAll,
      contentSpacing: 7,
      child: Column(
        children: [
          if (visibleAlerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(child: Text('No alerts for this patient yet.')),
            )
          else
            for (final CaregiverAlert alert in visibleAlerts) ...[
              CaregiverAlertCard(
                alert: alert,
                expanded: _expandedAlertIds.contains(alert.id),
                onToggleExpanded: () => _toggle(alert.id),
                onViewMore: () => widget.onAlertTap(alert),
                onMarkAsSeen: widget.onMarkAsSeen == null
                    ? null
                    : () => widget.onMarkAsSeen!(alert),
              ),
              if (alert != visibleAlerts.last) const SizedBox(height: 7),
            ],
        ],
      ),
    );
  }
}
