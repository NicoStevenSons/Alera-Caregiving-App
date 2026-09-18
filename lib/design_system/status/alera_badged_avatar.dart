import 'package:flutter/material.dart';

import '../widgets/alera_patient_avatar.dart';
import 'alera_status_badge.dart';
import 'alera_status_descriptor.dart';

/// Patient avatar with a status badge overlaid in the bottom-right corner.
///
/// For global, multi-patient feeds (the Alerts page) where a badge alone
/// wouldn't say *who* triggered it — the photo carries identity, the badge
/// carries status. In a single-patient view, where identity is already
/// established by context, use [AleraStatusBadge] or an `AleraStatusChip`
/// standalone instead of repeating the patient's photo.
class AleraBadgedAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;

  final AleraStatusDescriptor status;

  /// Overrides the badge's accessible label without changing its tone/glyph.
  final String? statusLabelOverride;

  /// Ring colour around the badge. Defaults to the ambient surface colour;
  /// callers overlaying a differently-coloured card should pass their own so
  /// the ring doesn't visibly mismatch the card behind it.
  final Color? ringColor;

  final double ringWidth;

  /// Badge diameter as a fraction of the avatar's diameter (~35–40% per the
  /// agreed spec). Clamped to 14–22px so the badge stays legible on a small
  /// avatar and doesn't swallow the photo on a large one.
  final double badgeScale;

  const AleraBadgedAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 20,
    required this.status,
    this.statusLabelOverride,
    this.ringColor,
    this.ringWidth = 2,
    this.badgeScale = 0.38,
  }) : assert(
         badgeScale > 0 && badgeScale <= 1,
         'badgeScale must be a fraction of the avatar diameter.',
       );

  @override
  Widget build(BuildContext context) {
    final double avatarDiameter = radius * 2;
    final double badgeDiameter = (avatarDiameter * badgeScale)
        .clamp(14.0, 22.0)
        .toDouble();
    final Color resolvedRingColor =
        ringColor ?? Theme.of(context).colorScheme.surface;

    // Merges the avatar's "<name> avatar" semantics with the badge's status
    // label into one node, so a screen reader announces e.g.
    // "Maria Santos avatar, Critical" rather than two separate stops.
    return MergeSemantics(
      child: SizedBox(
        width: avatarDiameter,
        height: avatarDiameter,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            AleraPatientAvatar(name: name, photoUrl: photoUrl, radius: radius),
            Positioned(
              right: -ringWidth,
              bottom: -ringWidth,
              child: AleraStatusBadge(
                descriptor: status,
                labelOverride: statusLabelOverride,
                diameter: badgeDiameter,
                ringColor: resolvedRingColor,
                ringWidth: ringWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
