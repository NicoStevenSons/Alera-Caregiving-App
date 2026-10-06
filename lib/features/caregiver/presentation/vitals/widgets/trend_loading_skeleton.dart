import 'package:flutter/material.dart';

import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_skeleton.dart';

/// Loading placeholder shared by the vital, sleep and activity trend pages:
/// a card with a title line, the chart area and a footer line.
class TrendLoadingSkeleton extends StatelessWidget {
  const TrendLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const AleraCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AleraSkeletonBar(widthFactor: .4, height: 16),
        SizedBox(height: 16),
        AleraSkeletonBlock(height: 180),
        SizedBox(height: 16),
        AleraSkeletonBar(widthFactor: .6, height: 12),
      ],
    ),
  );
}
