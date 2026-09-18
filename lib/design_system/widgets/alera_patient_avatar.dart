import 'package:flutter/material.dart';

class AleraPatientAvatar extends StatelessWidget {
  const AleraPatientAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final initials = words
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    final seed = name.codeUnits.fold(0, (sum, value) => sum + value);
    const colors = [Color(0xFF8165C7), Color(0xFF4D91A8), Color(0xFFB36B8D)];

    return Semantics(
      image: true,
      label: '$name avatar',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: colors[seed % colors.length],
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
