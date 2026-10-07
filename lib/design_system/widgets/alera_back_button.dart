import 'package:flutter/material.dart';

import '../alera_colors.dart';

/// The one back control used across the app: a light grey chevron.
class AleraBackButton extends StatelessWidget {
  const AleraBackButton({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () => Navigator.maybePop(context),
      icon: Icon(Icons.chevron_left, size: size),
      color: AleraColors.mutedIcon,
    );
  }
}
