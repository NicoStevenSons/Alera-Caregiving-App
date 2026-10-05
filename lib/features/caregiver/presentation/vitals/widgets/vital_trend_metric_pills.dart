import 'package:flutter/material.dart';

import '../../../../../design_system/widgets/alera_pill.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';

class _MetricPillData {
  final String label;
  final String iconAsset;
  final bool available;

  const _MetricPillData({
    required this.label,
    required this.iconAsset,
    this.available = true,
  });
}

const _kMetricPills = [
  _MetricPillData(
    label: 'Heart Rate',
    iconAsset: 'alera-figma-assets/assets/icons/mini_status/heart_rate.svg',
  ),
  _MetricPillData(
    label: 'SpO₂',
    iconAsset: 'alera-figma-assets/assets/icons/mini_status/spo2.svg',
  ),
  _MetricPillData(
    label: 'Activity',
    iconAsset: 'alera-figma-assets/assets/icons/mini_status/activity.svg',
  ),
  _MetricPillData(
    label: 'Sleep',
    iconAsset: 'alera-figma-assets/assets/icons/mini_status/sleep.svg',
  ),
  // mini_status/ has no dedicated stress icon yet - this reuses the flat
  // (already-dimmed) vitals card icon as a stand-in, which also happens to
  // read as "disabled" without extra styling. Swap for a mini_status-style
  // stress icon once one exists, and flip `available` to true once there's
  // a trend page backing it.
  _MetricPillData(
    label: 'Stress',
    iconAsset: 'alera-figma-assets/assets/icons/vitals/card_icons/stress.svg',
    available: false,
  ),
];

/// Metric switcher row shown at the top of every vital trend page, built
/// from Alera's own filter pill (the same one used on the alerts page),
/// not a bespoke chip. Tapping a pill switches which metric's trend page is
/// showing; tapping the current metric or an unavailable one does nothing.
class VitalTrendMetricPills extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onUnavailable;

  const VitalTrendMetricPills({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: _kMetricPills.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final metric = _kMetricPills[index];
          final isSelected = metric.label == selected;

          return AleraPill(
            label: metric.label,
            leading: AleraSvgIcon(
              assetPath: metric.iconAsset,
              width: 20,
              height: 20,
            ),
            selected: isSelected,
            variant: AleraPillVariant.filter,
            onTap: isSelected
                ? null
                : () => metric.available
                      ? onSelected(metric.label)
                      : onUnavailable(metric.label),
          );
        },
      ),
    );
  }
}
