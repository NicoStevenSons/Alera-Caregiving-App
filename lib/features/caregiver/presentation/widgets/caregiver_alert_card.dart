import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../../../design_system/widgets/alera_patient_avatar.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../domain/models/caregiver_alert.dart';
import 'caregiver_alert_presentation.dart';

class CaregiverAlertCard extends StatelessWidget {
  final CaregiverAlert alert;
  final String? patientName;
  final VoidCallback? onToggleExpanded;
  final VoidCallback? onViewMore;
  final VoidCallback? onMarkAsSeen;
  final String? previousAverageText;
  final bool expanded;
  final bool unread;
  final bool showPatientName;

  const CaregiverAlertCard({
    super.key,
    required this.alert,
    this.patientName,
    this.onToggleExpanded,
    this.onViewMore,
    this.onMarkAsSeen,
    this.previousAverageText,
    this.expanded = false,
    this.unread = false,
    this.showPatientName = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color stripe = CaregiverAlertPresentation.accentColor(alert);
    final String largeIconPath = CaregiverAlertPresentation.largeIconPath(
      alert.metric,
    );
    final String badgeIconPath = CaregiverAlertPresentation.badgeAssetPath(
      alert.metric,
    );
    final String badgeLabel = CaregiverAlertPresentation.typeLabel(
      alert.metric,
    );
    final String name = patientName ?? 'Unknown patient';
    final _AlertCardDisplayData displayData = _buildDisplayData(
      alert,
      patientName,
      previousAverageText,
    );

    return AleraCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: unread ? const Color(0xFFFCFAFF) : Colors.white,
        borderRadius: BorderRadius.circular(2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggleExpanded,
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: stripe,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                // Reduced top, right, and bottom padding while maintaining left margin from the bar
                padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (showPatientName)
                          _AlertPatientAvatar(
                            name: name,
                            radius: 28,
                            badgeAssetPath: badgeIconPath,
                            badgeSemanticLabel: badgeLabel,
                          )
                        else
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: AleraSvgIcon(
                                assetPath: largeIconPath,
                                width: 56,
                                height: 56,
                                semanticLabel: alert.title,
                              ),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showPatientName && name.isNotEmpty)
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: AleraColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              Text(
                                alert.title,
                                style: AleraTypography.label.copyWith(
                                  color: AleraColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  expanded
                                      ? displayData.detectedAt
                                      : '${displayData.reading} • ${displayData.relativeTime}',
                                  key: ValueKey(expanded),
                                  style: AleraTypography.body.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: const Color(0xFFB7B2C3),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    // Mount the expanded actions at their full, tappable size on
                    // the expansion frame, as in the original card interaction.
                    if (expanded)
                      Padding(
                        key: const ValueKey('expanded-details'),
                        padding: const EdgeInsets.only(top: 8),
                        child: _ExpandedDetails(
                          data: displayData,
                          onViewMore: onViewMore,
                          onMarkAsSeen: onMarkAsSeen,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dateTime) {
    final Duration elapsed = DateTime.now().difference(dateTime);
    if (elapsed.isNegative) return 'just now';

    final int minutes = elapsed.inMinutes;
    if (minutes <= 1) return 'just now';
    if (minutes < 60) return '$minutes mins ago';

    final int hours = elapsed.inHours;
    if (hours < 24) return '$hours hr${hours == 1 ? '' : 's'} ago';

    final int days = elapsed.inDays;
    if (days < 7) return '$days day${days == 1 ? '' : 's'} ago';

    if (days < 30) {
      final int weeks = days ~/ 7;
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    }

    if (days < 365) {
      final int months = days ~/ 30;
      return '$months month${months == 1 ? '' : 's'} ago';
    }

    final int years = days ~/ 365;
    return '$years year${years == 1 ? '' : 's'} ago';
  }
}

class _AlertPatientAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final String badgeAssetPath;
  final String badgeSemanticLabel;

  const _AlertPatientAvatar({
    required this.name,
    required this.radius,
    required this.badgeAssetPath,
    required this.badgeSemanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final double diameter = radius * 2;

    return MergeSemantics(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AleraPatientAvatar(name: name, radius: radius),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: AleraSvgIcon(
                  assetPath: badgeAssetPath,
                  width: 20,
                  height: 20,
                  semanticLabel: '$badgeSemanticLabel alert',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCardDisplayData {
  final String metricLabel;
  final String reading;
  final String? secondaryLabel;
  final String? secondaryValue;
  final String threshold;
  final String duration;
  final String detectedAt;
  final String status;
  final String reason;
  final String relativeTime;

  const _AlertCardDisplayData({
    required this.metricLabel,
    required this.reading,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.threshold,
    required this.duration,
    required this.detectedAt,
    required this.status,
    required this.reason,
    required this.relativeTime,
  });
}

_AlertCardDisplayData _buildDisplayData(
  CaregiverAlert alert,
  String? patientName,
  String? previousAverageText,
) {
  final String value = alert.reading % 1 == 0
      ? alert.reading.toStringAsFixed(0)
      : alert.reading.toStringAsFixed(1);
  final String formattedReading = alert.unit.trim().isEmpty
      ? value
      : '$value ${alert.unit}';
  final String threshold = alert.threshold == null
      ? '--'
      : '${alert.threshold! % 1 == 0 ? alert.threshold!.toStringAsFixed(0) : alert.threshold!.toStringAsFixed(1)} ${alert.unit}';
  final Duration? duration = alert.triggerDuration;
  final DateTime localDetectedAt = alert.detectedAt.toLocal();
  final int hour = localDetectedAt.hour % 12 == 0
      ? 12
      : localDetectedAt.hour % 12;
  final String detected =
      '$hour:${localDetectedAt.minute.toString().padLeft(2, '0')} ${localDetectedAt.hour >= 12 ? 'PM' : 'AM'}';

  late final String metricLabel;
  late final String reading;
  String? secondaryLabel;
  String? secondaryValue;

  switch (alert.metric) {
    case CaregiverAlertMetric.heartRate:
      metricLabel = 'Heart Rate';
      reading = formattedReading;
      secondaryLabel = 'Previous Avg';
      secondaryValue = previousAverageText ?? '--';
      break;
    case CaregiverAlertMetric.spo2:
      metricLabel = 'SpO₂';
      reading = formattedReading;
      secondaryLabel = 'Previous Avg';
      secondaryValue = previousAverageText ?? '--';
      break;
    case CaregiverAlertMetric.activity:
      metricLabel = 'Activity';
      reading = alert.conditionKey == 'INACTIVITY'
          ? 'No movement detected'
          : _eventValue(alert, formattedReading);
      break;
    case CaregiverAlertMetric.sleep:
      metricLabel = 'Sleep';
      reading = _eventValue(alert, formattedReading);
      break;
    case CaregiverAlertMetric.watchBattery:
      metricLabel = 'Battery level';
      reading = formattedReading;
      secondaryLabel = 'Device';
      secondaryValue = _deviceLabel(alert) ?? 'Device';
      break;
    case CaregiverAlertMetric.system:
      final String? device = _deviceLabel(alert);
      metricLabel = device == null ? 'System' : 'Device';
      reading = device ?? alert.title;
      switch (alert.conditionKey) {
        case 'PHONE_DISCONNECTED':
        case 'WATCH_DISCONNECTED':
        case 'DEVICE_DISCONNECTED':
          secondaryLabel = 'Connection';
          secondaryValue = 'Disconnected';
          break;
        case 'SYNC_FAILURE':
          secondaryLabel = 'Sync';
          secondaryValue = 'Failed';
          break;
        default:
          break;
      }
      break;
  }

  return _AlertCardDisplayData(
    metricLabel: metricLabel,
    reading: reading,
    secondaryLabel: secondaryLabel,
    secondaryValue: secondaryValue,
    threshold: threshold,
    duration: duration == null ? '--' : '${duration.inMinutes} min',
    detectedAt: detected,
    status: switch (alert.status) {
      CaregiverAlertStatus.active => 'Active',
      CaregiverAlertStatus.acknowledged => 'Acknowledged',
      CaregiverAlertStatus.resolved => 'Resolved',
      CaregiverAlertStatus.falseAlarm => 'False alarm',
    },
    reason: alert.description.isEmpty ? 'Not specified' : alert.description,
    relativeTime: CaregiverAlertCard._relativeTime(alert.detectedAt),
  );
}

String _eventValue(CaregiverAlert alert, String formattedReading) {
  if (alert.unit.trim().isEmpty && alert.reading == 0) return alert.title;
  return formattedReading;
}

String? _deviceLabel(CaregiverAlert alert) {
  return switch (alert.conditionKey) {
    'PHONE_DISCONNECTED' || 'PHONE_BATTERY_LOW' => 'Patient phone',
    'WATCH_DISCONNECTED' || 'WATCH_BATTERY_LOW' => 'Smartwatch',
    'DEVICE_DISCONNECTED' || 'BATTERY_LOW' => 'Device',
    _ => null,
  };
}

class _ExpandedDetails extends StatelessWidget {
  final _AlertCardDisplayData data;
  final VoidCallback? onViewMore;
  final VoidCallback? onMarkAsSeen;

  const _ExpandedDetails({
    required this.data,
    required this.onViewMore,
    required this.onMarkAsSeen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Detail(label: data.metricLabel, value: data.reading),
                  const SizedBox(height: 8),
                  _Detail(label: 'Status', value: data.status),
                ],
              ),
            ),
            if (data.secondaryLabel != null && data.secondaryValue != null)
              Expanded(
                child: _Detail(
                  label: data.secondaryLabel!,
                  value: data.secondaryValue!,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AleraButton(
                label: 'View Details',
                onPressed: onViewMore,
                variant: AleraButtonVariant.secondary,
                expand: true,
                height: 40,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AleraButton(
                label: 'Mark as Seen',
                onPressed: onMarkAsSeen,
                variant: AleraButtonVariant.secondary,
                expand: true,
                height: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;

  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AleraTypography.body.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(value, style: AleraTypography.body.copyWith(fontSize: 11)),
      ],
    );
  }
}
