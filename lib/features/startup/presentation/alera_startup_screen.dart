import 'package:flutter/material.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_typography.dart';

class AleraStartupScreen extends StatelessWidget {
  const AleraStartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/alera-logo-no-padding.png',
                    width: 112,
                    height: 112,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 22),

                  const Text(
                    'Alera',
                    style: AleraTypography.pageTitle,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Care, connected.',
                    style: AleraTypography.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 42,
              child: Column(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AleraColors.primary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Getting things ready...',
                    style: AleraTypography.label.copyWith(
                      color: AleraColors.textSecondary.withValues(alpha: 0.72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
