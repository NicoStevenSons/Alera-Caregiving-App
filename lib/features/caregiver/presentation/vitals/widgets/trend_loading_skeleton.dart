import 'package:flutter/material.dart';

import '../../../../../design_system/alera_spacing.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_skeleton.dart';

/// Loading placeholder for the trend pages, shaped like the loaded layout
/// (stat row, chart card, summary card) so nothing jumps when data lands.
/// Built from the design system's pulsing skeleton primitives.
class TrendLoadingSkeleton extends StatelessWidget {
  const TrendLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _StatRowSkeleton(),
        SizedBox(height: 12),
        _ChartCardSkeleton(),
        SizedBox(height: 12),
        _SummaryCardSkeleton(),
        SizedBox(height: 12),
      ],
    );
  }
}

class _StatRowSkeleton extends StatelessWidget {
  const _StatRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AleraSpacing.medium,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: AleraSpacing.small),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AleraSkeletonCircle(size: 32),
                  SizedBox(height: 8),
                  AleraSkeletonBar(widthFactor: .6, height: 8),
                  SizedBox(height: 6),
                  AleraSkeletonBar(widthFactor: .85, height: 12),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartCardSkeleton extends StatelessWidget {
  const _ChartCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AleraCard(
      padding: EdgeInsets.fromLTRB(14, 16, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AleraSkeletonBar(widthFactor: .55, height: 14),
                    SizedBox(height: 8),
                    AleraSkeletonBar(widthFactor: .7, height: 9),
                  ],
                ),
              ),
              SizedBox(width: 16),
              AleraSkeletonBlock(width: 64, height: 28, borderRadius: 14),
            ],
          ),
          SizedBox(height: 14),
          AleraSkeletonBlock(height: 200, borderRadius: 12),
        ],
      ),
    );
  }
}

class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AleraCard(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          AleraSkeletonCircle(size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AleraSkeletonBar(widthFactor: .4, height: 12),
                SizedBox(height: 8),
                AleraSkeletonBar(widthFactor: .95, height: 9),
                SizedBox(height: 6),
                AleraSkeletonBar(widthFactor: .7, height: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
