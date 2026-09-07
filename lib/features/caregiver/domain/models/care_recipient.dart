import 'health_snapshot.dart';

enum CareStatus { critical, warning, stable, noData, unknown, needsAttention }

class CareRecipient {
  final String id;
  final String name;
  final String relationshipLabel;
  final String? addressOrRoom;
  final String monitoringStatusLabel;
  final bool backendBacked;
  final CareStatus status;
  final int alertCount;
  final int reminderCount;
  final List<String> quickMessages;
  final HealthSnapshot healthSnapshot;

  const CareRecipient({
    required this.id,
    required this.name,
    required this.relationshipLabel,
    this.addressOrRoom,
    this.monitoringStatusLabel = 'Stable',
    this.backendBacked = false,
    required this.status,
    required this.alertCount,
    required this.reminderCount,
    required this.quickMessages,
    required this.healthSnapshot,
  });
}
