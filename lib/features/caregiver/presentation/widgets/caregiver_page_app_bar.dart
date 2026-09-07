import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';

class CaregiverPageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CaregiverPageAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Text(title, style: AleraTypography.pageTitle),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

IconButton caregiverPageAction({
  required String tooltip,
  required VoidCallback onPressed,
  required IconData icon,
}) {
  return IconButton(
    tooltip: tooltip,
    color: AleraColors.primarySoft,
    iconSize: 24,
    onPressed: onPressed,
    icon: Icon(icon),
  );
}
