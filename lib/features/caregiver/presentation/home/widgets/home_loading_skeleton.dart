import 'package:flutter/material.dart';

import '../../../../../design_system/widgets/alera_skeleton.dart';

/// Placeholder for dashboard data; patient identity stays visible above it.
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('home-loading-skeleton'),
      children: [
        for (final rows in [3, 2, 2, 3]) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AleraSkeletonBar(widthFactor: .4, height: 16),
                const SizedBox(height: 16),
                for (var index = 0; index < rows; index++) ...[
                  const Row(
                    children: [
                      AleraSkeletonBlock(
                        width: 32,
                        height: 32,
                        borderRadius: 8,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AleraSkeletonBar(widthFactor: .65, height: 12),
                            SizedBox(height: 8),
                            AleraSkeletonBar(widthFactor: .4, height: 9),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (index < rows - 1) const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
