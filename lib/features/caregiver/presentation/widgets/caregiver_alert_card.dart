import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../../../design_system/widgets/alera_patient_avatar.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../domain/models/caregiver_alert.dart';

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
    final bool critical = alert.severity == CaregiverAlertSeverity.critical;
    final Color stripe = critical ? AleraColors.critical : AleraColors.warning;
    final String largeIconPath = switch (alert.metric) {
      CaregiverAlertMetric.heartRate =>
        'alera-figma-assets/assets/icons/vitals/heart_rate.svg',
      CaregiverAlertMetric.spo2 =>
        'alera-figma-assets/assets/icons/vitals/spo2.svg',
      CaregiverAlertMetric.watchBattery =>
        'alera-figma-assets/assets/icons/status/info.svg',
      CaregiverAlertMetric.system =>
        'alera-figma-assets/assets/icons/status/info.svg',
    };
    final String badgeIconPath = switch (alert.metric) {
      CaregiverAlertMetric.heartRate =>
        'alera-figma-assets/assets/icons/mini_status/heart_rate.svg',
      CaregiverAlertMetric.spo2 =>
        'alera-figma-assets/assets/icons/mini_status/spo2.svg',
      CaregiverAlertMetric.watchBattery =>
        'alera-figma-assets/assets/icons/mini_status/info.svg',
      CaregiverAlertMetric.system =>
        'alera-figma-assets/assets/icons/mini_status/system.svg',
    };
    final String badgeLabel = switch (alert.metric) {
      CaregiverAlertMetric.heartRate => 'Heart rate',
      CaregiverAlertMetric.spo2 => 'SpO₂',
      CaregiverAlertMetric.watchBattery => 'Battery',
      CaregiverAlertMetric.system => 'System',
    };
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
  final String previousAverage;
  final String threshold;
  final String duration;
  final String detectedAt;
  final String status;
  final String reason;
  final String relativeTime;

  const _AlertCardDisplayData({
    required this.metricLabel,
    required this.reading,
    required this.previousAverage,
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
  return _AlertCardDisplayData(
    metricLabel: switch (alert.metric) {
      CaregiverAlertMetric.heartRate => 'Heart Rate',
      CaregiverAlertMetric.spo2 => 'SpO₂',
      CaregiverAlertMetric.watchBattery => 'Battery',
      CaregiverAlertMetric.system => 'System',
    },
    reading: alert.metric == CaregiverAlertMetric.system && alert.unit.isEmpty
        ? '--'
        : '$value ${alert.unit}',
    previousAverage: previousAverageText ?? '--',
    threshold: threshold,
    duration: duration == null ? '--' : '${duration.inMinutes} min',
    detectedAt: detected,
    status: switch (alert.status) {
      CaregiverAlertStatus.active =>
        alert.severity == CaregiverAlertSeverity.critical
            ? 'Critical'
            : 'Elevated',
      CaregiverAlertStatus.acknowledged => 'Acknowledged',
      CaregiverAlertStatus.resolved => 'Resolved',
      CaregiverAlertStatus.falseAlarm => 'False alarm',
    },
    reason: alert.description.isEmpty ? 'Not specified' : alert.description,
    relativeTime: CaregiverAlertCard._relativeTime(alert.detectedAt),
  );
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
            Expanded(
              child: _Detail(
                label: 'Previous Avg',
                value: data.previousAverage,
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
    return RichText(
      text: TextSpan(
        style: AleraTypography.body.copyWith(fontSize: 11),
        children: [
          TextSpan(
            text: '$label\n',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
