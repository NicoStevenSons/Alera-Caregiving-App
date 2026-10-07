import 'package:flutter/material.dart';

import '../../../../../design_system/widgets/alera_empty_state.dart';
import '../../../../../design_system/widgets/alera_section_card.dart';
import '../../../domain/models/caregiver_alert.dart';
import '../../widgets/caregiver_alert_card.dart';

/// Active alerts only. Everything older lives behind "View history" so the
/// patient page stays about what needs doing now.
class PatientNeedsAttention extends StatefulWidget {
  final List<CaregiverAlert> alerts;
  final VoidCallback onViewHistory;
  final ValueChanged<CaregiverAlert> onAlertTap;
  final ValueChanged<CaregiverAlert>? onMarkAsSeen;

  const PatientNeedsAttention({
    super.key,
    required this.alerts,
    required this.onViewHistory,
    required this.onAlertTap,
    this.onMarkAsSeen,
  });

  @override
  State<PatientNeedsAttention> createState() => _PatientNeedsAttentionState();
}

class _PatientNeedsAttentionState extends State<PatientNeedsAttention> {
  final Set<String> _expandedAlertIds = <String>{};

  void _toggle(String id) {
    setState(() {
      if (!_expandedAlertIds.add(id)) _expandedAlertIds.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<CaregiverAlert> active =
        widget.alerts
            .where((alert) => alert.status == CaregiverAlertStatus.active)
            .toList()
          ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    final List<CaregiverAlert> visible = active.take(3).toList();

    return AleraSectionCard(
      title: 'Needs attention',
      actionLabel: 'View history',
      onActionPressed: widget.onViewHistory,
      contentSpacing: 7,
      child: Column(
        children: [
          if (visible.isEmpty)
            const AleraEmptyState(
              key: Key('patient-no-active-alerts'),
              assetPath:
                  'alera-figma-assets/assets/icons/status/no-active-alerts.svg',
              title: 'No active alerts',
              message: 'Nothing needs attention right now.',
              padding: EdgeInsets.symmetric(vertical: 14),
            )
          else
            for (final CaregiverAlert alert in visible) ...[
              CaregiverAlertCard(
                alert: alert,
                expanded: _expandedAlertIds.contains(alert.id),
                onToggleExpanded: () => _toggle(alert.id),
                onViewMore: () => widget.onAlertTap(alert),
                onMarkAsSeen: widget.onMarkAsSeen == null
                    ? null
                    : () => widget.onMarkAsSeen!(alert),
              ),
              if (alert != visible.last) const SizedBox(height: 7),
            ],
        ],
      ),
    );
  }
}
