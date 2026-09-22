import 'package:flutter/material.dart';

/// Patient avatar: a photo when [photoUrl] is present and loads, otherwise
/// deterministic initials on a colour picked from the patient's name.
///
/// The initials/colour derivation never changes based on [photoUrl] loading
/// state, so the fallback looks identical whether it's showing because no
/// photo was given or because one failed to load.
class AleraPatientAvatar extends StatelessWidget {
  final String name;

  /// Network image URL. Null or empty renders initials directly, with no
  /// image request attempted.
  final String? photoUrl;

  final double radius;

  const AleraPatientAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 20,
  });

  bool get _hasUsablePhotoUrl {
    final String? url = photoUrl;
    return url != null && url.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final Iterable<String> words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty);
    final String initials = words
        .take(2)
        .map((String word) => word.characters.first.toUpperCase())
        .join();
    final int seed = name.codeUnits.fold(
      0,
      (int sum, int value) => sum + value,
    );
    const List<Color> colors = <Color>[
      Color(0xFF8165C7),
      Color(0xFF4D91A8),
      Color(0xFFB36B8D),
    ];

    Widget initialsAvatar() => Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: colors[seed % colors.length],
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Semantics(
      image: true,
      label: '$name avatar',
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: _hasUsablePhotoUrl
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => initialsAvatar(),
                )
              : initialsAvatar(),
        ),
      ),
    );
  }
}
