import 'package:flutter/material.dart';

import '../alera_colors.dart';

/// The one Alera loading spinner. Use [AleraLoader.small] inside buttons and
/// rows, the default for inline loading, and [AleraLoader.large] for a
/// full-page or section load. Always the brand purple unless a [color] is
/// given (for example white on a filled button).
class AleraLoader extends StatelessWidget {
  const AleraLoader({super.key, this.size = 28, this.color}) : _stroke = 3;

  /// 20px, for buttons and list rows.
  const AleraLoader.small({super.key, this.color}) : size = 20, _stroke = 2.4;

  /// 36px, for loading a whole page or section.
  const AleraLoader.large({super.key, this.color}) : size = 36, _stroke = 3.4;

  final double size;
  final Color? color;
  final double _stroke;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(
      strokeWidth: _stroke,
      color: color ?? AleraColors.primary,
    ),
  );
}
