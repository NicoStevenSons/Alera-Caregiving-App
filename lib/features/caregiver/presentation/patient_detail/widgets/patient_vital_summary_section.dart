import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../domain/models/health_snapshot.dart';

class PatientVitalSummarySection extends StatelessWidget {
  final HealthSnapshot snapshot;
  final ValueChanged<String> onVitalTap;

  const PatientVitalSummarySection({
    super.key,
    required this.snapshot,
    required this.onVitalTap,
  });

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vitals', style: AleraTypography.sectionTitle),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _VitalCard(
                  backgroundAsset:
                      'alera-figma-assets/assets/icons/vitals/cards/heart_rate_background.svg',
                  iconAsset:
                      'alera-figma-assets/assets/icons/vitals/card_icons/heart_rate.svg',
                  title: 'Heart Rate',
                  value: snapshot.heartRateBpm?.toString() ?? 'Unavailable',
                  unit: snapshot.heartRateBpm == null
                      ? ''
                      : snapshot.heartRateUnit ?? 'bpm',
                  textColor: const Color(0xFFA50036),
                  onTap: () => onVitalTap('Heart Rate'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VitalCard(
                  backgroundAsset:
                      'alera-figma-assets/assets/icons/vitals/cards/spo2_background.svg',
                  iconAsset:
                      'alera-figma-assets/assets/icons/vitals/card_icons/spo2.svg',
                  title: 'SpO₂',
                  value:
                      snapshot.spo2Percent?.toStringAsFixed(0) ?? 'Unavailable',
                  unit: snapshot.spo2Percent == null
                      ? ''
                      : snapshot.spo2Unit ?? '%',
                  textColor: const Color(0xFF3729AC),
                  onTap: () => onVitalTap('SpO₂'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _UnavailableVitalCard(
                  backgroundAsset:
                      'alera-figma-assets/assets/icons/vitals/cards/sleep_background.svg',
                  iconAsset:
                      'alera-figma-assets/assets/icons/vitals/card_icons/sleep.svg',
                  title: 'Sleep',
                  textColor: const Color(0xFF520EAB),
                  onTap: () => onVitalTap('Sleep'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _UnavailableVitalCard(
                  backgroundAsset:
                      'alera-figma-assets/assets/icons/vitals/cards/stress_background.svg',
                  iconAsset:
                      'alera-figma-assets/assets/icons/vitals/card_icons/stress.svg',
                  title: 'Stress',
                  textColor: const Color(0xFFA02D00),
                  onTap: () => onVitalTap('Stress'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _UnavailableVitalCard(
            backgroundAsset:
                'alera-figma-assets/assets/icons/vitals/cards/activity_background.svg',
            iconAsset:
                'alera-figma-assets/assets/icons/vitals/card_icons/activity.svg',
            title: 'Activity',
            textColor: const Color(0xFF3C6300),
            onTap: () => onVitalTap('Activity'),
          ),
        ],
      ),
    );
  }
}

class _UnavailableVitalCard extends StatelessWidget {
  final String backgroundAsset;
  final String iconAsset;
  final String title;
  final Color textColor;
  final VoidCallback onTap;

  const _UnavailableVitalCard({
    required this.backgroundAsset,
    required this.iconAsset,
    required this.title,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _VitalCard(
      backgroundAsset: backgroundAsset,
      iconAsset: iconAsset,
      title: title,
      value: 'Unavailable',
      unit: '',
      textColor: textColor,
      onTap: onTap,
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String backgroundAsset;
  final String iconAsset;
  final String title;
  final String value;
  final String unit;
  final Color textColor;
  final VoidCallback onTap;

  const _VitalCard({
    required this.backgroundAsset,
    required this.iconAsset,
    required this.title,
    required this.value,
    required this.unit,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor = textColor.withValues(alpha: 0.50);
    final bool isUnavailable = value == 'Unavailable';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 170,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(backgroundAsset, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AleraSvgIcon(
                          assetPath: iconAsset,
                          width: 20,
                          height: 20,
                          semanticLabel: title,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 26),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Transform.translate(
                              // Offsets ONLY the "Unavailable" text upward by 3 pixels
                              offset: Offset(0, isUnavailable ? -3 : 0),
                              child: Text(
                                value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: isUnavailable ? 16 : 30,
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                  textBaseline: TextBaseline.alphabetic,
                                ),
                              ),
                            ),
                          ),
                          if (!isUnavailable && unit.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              unit,
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 16,
                                height: 1.1,
                                fontWeight: FontWeight.w500,
                                textBaseline: TextBaseline.alphabetic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Icon(
                  Icons.chevron_right,
                  color: secondaryColor,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
