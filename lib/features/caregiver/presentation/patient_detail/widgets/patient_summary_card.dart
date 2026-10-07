import 'package:flutter/material.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_spacing.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_patient_avatar.dart';
import '../../../domain/models/care_recipient.dart';
import '../../../domain/models/health_snapshot.dart';

/// Patient header: avatar, name, relationship line,
/// a live connection pill, and the actions (Call as the primary pill, the
/// rest as round tonal icon buttons).
class PatientDetailSummaryCard extends StatelessWidget {
  final CareRecipient careRecipient;
  final ValueChanged<String> onAction;

  const PatientDetailSummaryCard({
    super.key,
    required this.careRecipient,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = careRecipient.healthSnapshot;
    final subtitle = snapshot.hasLastCheckIn
        ? '${careRecipient.relationshipLabel} · Last check-in ${_time(snapshot.lastCheckIn)}'
        : '${careRecipient.relationshipLabel} · No check-in yet';

    return AleraCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              AleraPatientAvatar(
                name: careRecipient.name,
                photoUrl: careRecipient.profilePhotoUrl,
                radius: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      careRecipient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AleraTypography.sectionTitle.copyWith(
                        fontSize: 18,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AleraTypography.body.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    PatientConnectionPill(
                      key: const Key('patient-connection-pill'),
                      devices: snapshot.devices,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Material(
                  color: AleraColors.selected,
                  borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      AleraSpacing.cardRadius,
                    ),
                    onTap: () => onAction('Call'),
                    child: const SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Call',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _RoundAction(
                icon: Icons.message,
                label: 'Message',
                onTap: () => onAction('Message'),
              ),
              _RoundAction(
                icon: Icons.notifications_active,
                label: 'Remind',
                onTap: () => onAction('Reminder'),
              ),
              _RoundAction(
                icon: Icons.edit,
                label: 'Note',
                onTap: () => onAction('Add Note'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$hour:${value.minute.toString().padLeft(2, '0')} '
        '${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}

/// "● Connected / Disconnected / No device" pill from the patient's devices.
class PatientConnectionPill extends StatelessWidget {
  final List<MonitoringDevice> devices;

  const PatientConnectionPill({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    final MonitoringDevice? watch = devices.watch;
    final bool anyConnected = devices.any((d) => d.isConnected);
    final bool known = devices.any(
      (d) => d.connectionStatus != MonitoringDeviceConnectionStatus.unknown,
    );
    final bool connected = watch?.isConnected ?? anyConnected;

    final String label = connected
        ? 'Connected'
        : known
        ? 'Disconnected'
        : 'No device';
    final Color color = connected
        ? AleraColors.successStrong
        : known
        ? AleraColors.critical
        : AleraColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small "● Stable" style pill coloured by the patient's care status.
class PatientStatusPill extends StatelessWidget {
  final CareStatus status;

  const PatientStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color = patientStatusColor(status);
    return Container(
      key: const Key('patient-status-pill'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            patientStatusTitle(status),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Readable-on-tint accent for each care status.
Color patientStatusColor(CareStatus status) => switch (status) {
  CareStatus.stable => AleraColors.successStrong,
  CareStatus.warning || CareStatus.needsAttention => AleraColors.warningStrong,
  CareStatus.critical => AleraColors.criticalStrong,
  CareStatus.noData || CareStatus.unknown => AleraColors.textSecondary,
};

String patientStatusTitle(CareStatus status) => switch (status) {
  CareStatus.stable => 'Stable',
  CareStatus.warning => 'Warning',
  CareStatus.critical => 'Critical',
  CareStatus.needsAttention => 'Needs attention',
  CareStatus.noData => 'No data',
  CareStatus.unknown => 'Unknown',
};

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: AleraColors.selected,
        borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
          onTap: onTap,
          child: Semantics(
            button: true,
            label: label,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
