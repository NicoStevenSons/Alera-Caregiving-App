import 'package:flutter/material.dart';

import '../../../../design_system/widgets/alera_page_app_bar.dart';

class CaregiverPageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CaregiverPageAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AleraPageAppBar(
      title: title,
      actions: actions,
      automaticallyImplyLeading: false,
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
  return aleraPageAction(tooltip: tooltip, onPressed: onPressed, icon: icon);
}
