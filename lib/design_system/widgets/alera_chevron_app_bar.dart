import 'package:flutter/material.dart';

/// App bar with only a light back chevron (no title), matching the alert
/// detail page.
class AleraChevronAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AleraChevronAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.chevron_left, size: 28),
        color: const Color(0xFFB4AEC2),
      ),
    );
  }
}
