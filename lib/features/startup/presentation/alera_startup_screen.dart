import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_typography.dart';

class AleraStartupScreen extends StatelessWidget {
  const AleraStartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final isCompact = height < 700;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'alera-figma-assets/assets/icons/onboarding/alera-logo.svg',
                              width: isCompact ? 220 : 250,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: isCompact ? 36 : 50),
                            Text(
                              'Welcome to Alera',
                              textAlign: TextAlign.center,
                              style: AleraTypography.pageTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connect with your household.',
                              textAlign: TextAlign.center,
                              style: AleraTypography.body.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
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
                        const SizedBox(height: 10),
                        Text(
                          'Getting things ready...',
                          textAlign: TextAlign.center,
                          style: AleraTypography.label.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
