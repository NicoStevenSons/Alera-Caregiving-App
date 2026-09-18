import 'package:flutter/material.dart';

import '../alera_colors.dart';
import '../alera_typography.dart';

class AleraPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AleraPageAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: AleraColors.surface,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: automaticallyImplyLeading,
    titleSpacing: 16,
    title: Text(title, style: AleraTypography.pageTitle),
    actions: actions,
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

IconButton aleraPageAction({
  required String tooltip,
  required VoidCallback onPressed,
  required IconData icon,
}) => IconButton(
  tooltip: tooltip,
  color: AleraColors.primarySoft,
  iconSize: 24,
  onPressed: onPressed,
  icon: Icon(icon),
);
