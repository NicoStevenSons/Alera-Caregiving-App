import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';

/// Pushes [builder] inside the current (elderly) theme so detail pages keep
/// the larger type, buttons and app bar.
Route<T> elderlyRoute<T>(BuildContext context, WidgetBuilder builder) {
  final ThemeData theme = Theme.of(context);
  return MaterialPageRoute<T>(
    builder: (BuildContext routeContext) =>
        Theme(data: theme, child: Builder(builder: builder)),
  );
}

/// Rounded tinted square holding a filled Material icon.
class ElderlyIconTile extends StatelessWidget {
  const ElderlyIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.58),
    );
  }
}

class ElderlySectionTitle extends StatelessWidget {
  const ElderlySectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AleraColors.textPrimary,
      ),
    );
  }
}

/// Small coloured status label ("Due", "Completed", ...).
class ElderlyStatusChip extends StatelessWidget {
  const ElderlyStatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// Colourful vital tile that reuses the caregiver vital art, scaled up.
class ElderlyVitalTile extends StatelessWidget {
  const ElderlyVitalTile({
    super.key,
    required this.backgroundAsset,
    required this.iconAsset,
    required this.title,
    required this.value,
    this.unit = '',
    required this.caption,
    required this.textColor,
    required this.onTap,
  });

  static const String _vitals = 'alera-figma-assets/assets/icons/vitals';

  static const String heartBackground = '$_vitals/cards/heart_rate_background.svg';
  static const String heartIcon = '$_vitals/card_icons/heart_rate.svg';
  static const String spo2Background = '$_vitals/cards/spo2_background.svg';
  static const String spo2Icon = '$_vitals/card_icons/spo2.svg';
  static const String sleepBackground = '$_vitals/cards/sleep_background.svg';
  static const String sleepIcon = '$_vitals/card_icons/sleep.svg';
  static const String activityBackground = '$_vitals/cards/activity_background.svg';
  static const String activityIcon = '$_vitals/card_icons/activity.svg';

  static const Color heartColor = Color(0xFFA50036);
  static const Color spo2Color = Color(0xFF3729AC);
  static const Color sleepColor = Color(0xFF520EAB);
  static const Color activityColor = Color(0xFF3C6300);

  final String backgroundAsset;
  final String iconAsset;
  final String title;
  final String value;
  final String unit;
  final String caption;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 176,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(backgroundAsset, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AleraSvgIcon(
                          assetPath: iconAsset,
                          width: 28,
                          height: 28,
                          semanticLabel: title,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 36,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (unit.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              unit,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.75),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
