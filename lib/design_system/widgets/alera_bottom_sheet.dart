import 'package:flutter/material.dart';

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
