import 'package:flutter/material.dart';

/// Patient avatar: a photo when [photoUrl] is present and loads, otherwise
/// deterministic initials on a colour picked from the patient's name.
///
/// The initials/colour derivation never changes based on [photoUrl] loading
/// state, so the fallback looks identical whether it's showing because no
/// photo was given or because one failed to load.
class AleraPatientAvatar extends StatefulWidget {
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

  @override
  State<AleraPatientAvatar> createState() => _AleraPatientAvatarState();
}

class _AleraPatientAvatarState extends State<AleraPatientAvatar> {
  bool _imageFailed = false;

  @override
  void didUpdateWidget(covariant AleraPatientAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A changed URL deserves a fresh attempt rather than staying stuck on a
    // previous failure.
    if (oldWidget.photoUrl != widget.photoUrl) {
      _imageFailed = false;
    }
  }

  bool get _hasUsablePhotoUrl {
    final String? url = widget.photoUrl;
    return url != null && url.trim().isNotEmpty;
  }

  bool get _showsPhoto => _hasUsablePhotoUrl && !_imageFailed;

  void _handleImageError(Object exception, StackTrace? stackTrace) {
    if (!mounted || _imageFailed) return;
    setState(() => _imageFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    final Iterable<String> words = widget.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty);
    final String initials = words
        .take(2)
        .map((String word) => word.characters.first.toUpperCase())
        .join();
    final int seed = widget.name.codeUnits.fold(
      0,
      (int sum, int value) => sum + value,
    );
    const List<Color> colors = <Color>[
      Color(0xFF8165C7),
      Color(0xFF4D91A8),
      Color(0xFFB36B8D),
    ];

    return Semantics(
      image: true,
      label: '${widget.name} avatar',
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: colors[seed % colors.length],
        backgroundImage: _showsPhoto ? NetworkImage(widget.photoUrl!) : null,
        onBackgroundImageError: _showsPhoto ? _handleImageError : null,
        child: _showsPhoto
            ? null
            : Text(
                initials.isEmpty ? '?' : initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.radius * 0.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
