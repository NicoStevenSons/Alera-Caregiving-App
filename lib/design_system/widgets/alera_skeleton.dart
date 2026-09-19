import 'package:flutter/material.dart';

abstract final class AleraSkeletonColors {
  static const Color placeholder = Color(0xFFE5DCF5);
}

class AleraSkeletonBar extends StatelessWidget {
  final double widthFactor;
  final double height;

  const AleraSkeletonBar({
    super.key,
    required this.widthFactor,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AleraSkeletonColors.placeholder,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

class AleraSkeletonCircle extends StatelessWidget {
  final double size;

  const AleraSkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AleraSkeletonColors.placeholder,
        shape: BoxShape.circle,
      ),
    );
  }
}

class AleraSkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const AleraSkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AleraSkeletonColors.placeholder,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
