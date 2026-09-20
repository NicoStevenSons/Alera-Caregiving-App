import 'package:flutter/material.dart';

import 'alera_colors.dart';

abstract final class AleraTypography {
  static const TextStyle pageTitle = TextStyle(
    color: AleraColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AleraColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    color: AleraColors.textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    color: AleraColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}
