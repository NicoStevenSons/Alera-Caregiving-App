import 'package:flutter/material.dart';

import 'alera_back_button.dart';

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
      leading: const AleraBackButton(),
    );
  }
}
