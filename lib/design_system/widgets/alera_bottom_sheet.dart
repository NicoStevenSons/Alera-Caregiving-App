import 'package:flutter/material.dart';

import '../alera_spacing.dart';
import '../alera_typography.dart';

Future<T?> showAleraBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  showDragHandle: true,
  useSafeArea: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  builder: builder,
);

class AleraBottomSheetShell extends StatelessWidget {
  const AleraBottomSheetShell({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.actions,
    this.showCloseButton = true,
  });

  final String title;
  final String? description;
  final Widget child;
  final Widget? actions;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AleraSpacing.medium,
          0,
          AleraSpacing.medium,
          AleraSpacing.medium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: AleraTypography.sectionTitle)),
                if (showCloseButton)
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            if (description != null) ...[
              Text(description!, style: AleraTypography.body),
              const SizedBox(height: AleraSpacing.small),
            ],
            Flexible(child: child),
            if (actions != null) ...[
              const SizedBox(height: AleraSpacing.medium),
              actions!,
            ],
          ],
        ),
      ),
    ),
  );
}
