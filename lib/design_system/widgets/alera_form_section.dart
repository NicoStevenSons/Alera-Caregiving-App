import 'package:flutter/material.dart';

import '../alera_spacing.dart';
import '../alera_typography.dart';

class AleraFormSection extends StatelessWidget {
  const AleraFormSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
    this.spacing = AleraSpacing.small,
  });

  final String title;
  final String? description;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AleraTypography.sectionTitle.copyWith(fontSize: 18)),
      if (description != null) ...[
        const SizedBox(height: AleraSpacing.xSmall),
        Text(description!, style: AleraTypography.body),
      ],
      const SizedBox(height: AleraSpacing.medium),
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) SizedBox(height: spacing),
        children[index],
      ],
    ],
  );
}
