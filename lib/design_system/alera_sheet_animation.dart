import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' show AnimationStyle;

/// Slide-up for every Alera pull-up drawer: a clear ease-out on the way in,
/// a slightly quicker ease-in on the way out. Pass as `sheetAnimationStyle`
/// to `showModalBottomSheet`.
const AnimationStyle aleraSheetAnimation = AnimationStyle(
  duration: Duration(milliseconds: 380),
  curve: Curves.easeOutCubic,
  reverseDuration: Duration(milliseconds: 260),
  reverseCurve: Curves.easeInCubic,
);
