import 'package:flutter/material.dart';

import '../../../../design_system/alera_spacing.dart';
import '../../../../design_system/widgets/alera_pill.dart';
import '../../domain/models/care_recipient.dart';
import '../../domain/models/caregiver_alert.dart';
import '../../domain/models/caregiver_reminder.dart';
import 'widgets/home_alerts_preview.dart';
import 'widgets/home_health_summary.dart';
import 'widgets/home_insights_card.dart';
import 'widgets/home_patient_header.dart';
import 'widgets/home_reminders_preview.dart';

class CaregiverHomePage extends StatelessWidget {
  static const List<String> _fallbackQuickMessages = [
    'Love you ❤️',
    'How are you? 😊',
    'Did you take meds? 💊',
    'Checking in 👋',
    'Call me 📞',
  ];

  final CareRecipient careRecipient;
  final List<CaregiverAlert> alerts;
  final List<CaregiverReminder> reminders;
  final VoidCallback onViewAllAlerts;
  final VoidCallback onViewAllReminders;
  final ValueChanged<CaregiverAlert> onAlertTap;
  final ValueChanged<CaregiverAlert>? onMarkAsSeen;
  final bool showDemoBanner;

  const CaregiverHomePage({
    super.key,
    required this.careRecipient,
    required this.alerts,
    required this.reminders,
    required this.onViewAllAlerts,
    required this.onViewAllReminders,
    required this.onAlertTap,
    this.onMarkAsSeen,
    this.showDemoBanner = false,
  });

  void _mock(BuildContext context, String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$action is mock-only for now.')));
  }

  @override
  Widget build(BuildContext context) {
    final List<String> quickMessages = careRecipient.quickMessages.isEmpty
        ? _fallbackQuickMessages
        : careRecipient.quickMessages;

    return ListView(
      key: const PageStorageKey<String>('caregiver-home-dashboard'),
      padding: EdgeInsets.zero,
      children: [
        if (showDemoBanner)
          Container(
            key: const Key('home-demo-fallback'),
            color: const Color(0xFFFFF1CC),
            padding: const EdgeInsets.all(10),
            child: const Text(
              'Demo data — the patient service is currently offline.',
              textAlign: TextAlign.center,
            ),
          ),
        HomePatientHeader(
          careRecipient: careRecipient,
          onCall: () => _mock(context, 'Call'),
          onMessage: () => _mock(context, 'Message'),
        ),
        SizedBox(
          height: 60,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AleraSpacing.medium,
              vertical: 14,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: quickMessages.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final String message = quickMessages[index];
              return AleraPill(
                label: message,
                variant: AleraPillVariant.action,
                onTap: () => _mock(context, 'Quick message'),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            children: [
              HomeHealthSummary(
                careRecipient: careRecipient,
                onMetricTap: (metric) => _mock(context, '$metric history'),
              ),
              const SizedBox(height: 12),
              HomeAlertsPreview(
                alerts: alerts,
                onViewAll: onViewAllAlerts,
                onAlertTap: onAlertTap,
                onMarkAsSeen: onMarkAsSeen,
              ),
              const SizedBox(height: 12),
              HomeInsightsCard(
                snapshot: careRecipient.healthSnapshot,
                backendBacked: careRecipient.backendBacked,
              ),
              const SizedBox(height: 12),
              HomeRemindersPreview(
                reminders: reminders,
                onViewAll: onViewAllReminders,
                onAction: (action) => _mock(context, action),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
