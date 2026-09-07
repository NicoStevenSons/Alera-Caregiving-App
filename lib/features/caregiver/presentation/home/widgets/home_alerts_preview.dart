import 'package:flutter/material.dart';

import '../../../../../design_system/widgets/alera_section_card.dart';
import '../../../domain/models/caregiver_alert.dart';
import '../../widgets/caregiver_alert_card.dart';

class HomeAlertsPreview extends StatefulWidget {
  final List<CaregiverAlert> alerts;
  final VoidCallback onViewAll;
  final ValueChanged<CaregiverAlert> onAlertTap;
  final ValueChanged<CaregiverAlert>? onMarkAsSeen;

  const HomeAlertsPreview({
    super.key,
    required this.alerts,
    required this.onViewAll,
    required this.onAlertTap,
    this.onMarkAsSeen,
  });

  @override
  State<HomeAlertsPreview> createState() => _HomeAlertsPreviewState();
}

class _HomeAlertsPreviewState extends State<HomeAlertsPreview> {
  final Set<String> _expandedAlertIds = <String>{};

  void _toggle(String id) {
    setState(() {
      if (!_expandedAlertIds.add(id)) _expandedAlertIds.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleAlerts = widget.alerts.take(2).toList();
    return AleraSectionCard(
      title: 'Alerts (${widget.alerts.length} active)',
      actionLabel: 'View All Alerts',
      onActionPressed: widget.onViewAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (visibleAlerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'No active alerts right now',
                      style: TextStyle(
                        color: Color(0xFFA69BD2),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'We’ll let you know if anything needs attention.',
                      style: TextStyle(color: Color(0xFFB5AADB), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            for (int index = 0; index < visibleAlerts.length; index++) ...[
              CaregiverAlertCard(
                alert: visibleAlerts[index],
                expanded: _expandedAlertIds.contains(visibleAlerts[index].id),
                onToggleExpanded: () => _toggle(visibleAlerts[index].id),
                onViewMore: () => widget.onAlertTap(visibleAlerts[index]),
                onMarkAsSeen: widget.onMarkAsSeen == null
                    ? null
                    : () => widget.onMarkAsSeen!(visibleAlerts[index]),
              ),
              if (index != visibleAlerts.length - 1) const SizedBox(height: 7),
            ],
        ],
      ),
    );
  }
}
