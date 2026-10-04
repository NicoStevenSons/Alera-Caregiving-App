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
    return _SkeletonPulse(
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AleraSkeletonColors.placeholder,
            borderRadius: BorderRadius.circular(height / 2),
          ),
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
    return _SkeletonPulse(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AleraSkeletonColors.placeholder,
          shape: BoxShape.circle,
        ),
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
    return _SkeletonPulse(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AleraSkeletonColors.placeholder,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class _SkeletonPulse extends StatefulWidget {
  final Widget child;

  const _SkeletonPulse({required this.child});

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = _controller.drive(
      Tween<double>(
        begin: 1,
        end: 0.45,
      ).chain(CurveTween(curve: Curves.easeInOut)),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) return widget.child;
    return FadeTransition(opacity: _opacity, child: widget.child);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
