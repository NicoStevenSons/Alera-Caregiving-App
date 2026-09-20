import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../../design_system/widgets/alera_svg_icon.dart';
import 'patient_setup_widgets.dart';

/// Payload encoded in the patient access QR code. The patient app decodes
/// this (see patient_access.dart), so the shape must stay `version: 2`.
/// Previously duplicated verbatim in add_patient_page.dart and
/// patient_access_setup_page.dart; both now import this single copy.
String buildPatientAccessQrPayload({required String accessCode}) => jsonEncode({
  'type': 'alera_patient_access',
  'version': 2,
  'access_code': accessCode,
});

/// Explainer shown before a code exists (Figma: "Patient access" intro).
class PatientAccessIntroContent extends StatelessWidget {
  const PatientAccessIntroContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SetupHeader(
          title: 'Patient access',
          subtitle:
              'Generate a one-time code for the patient to scan or enter to connect their Alera account.',
          bottomSpacing: 24,
        ),
        AleraCard(
          padding: const EdgeInsets.all(20),
          child: const Column(
            children: [
              _InfoRow(
                icon: Icons.schedule_outlined,
                title: 'Valid for 24 hours',
                subtitle: 'The code will expire after 24 hours.',
              ),
              SizedBox(height: 20),
              _InfoRow(
                icon: Icons.verified_user_outlined,
                title: 'One-time use only',
                subtitle: 'This code can only be used once.',
              ),
              SizedBox(height: 20),
              _InfoRow(
                icon: Icons.people_outline,
                title: 'For the patient',
                subtitle:
                    'Have the patient scan the QR code or enter the code on their device.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The issued code: text, QR, validity strip and Copy / Share actions.
class PatientAccessCodeContent extends StatelessWidget {
  final String accessCode;
  final DateTime expiresAt;
  final VoidCallback onShare;

  const PatientAccessCodeContent({
    super.key,
    required this.accessCode,
    required this.expiresAt,
    required this.onShare,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: accessCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Access code copied'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final expiry = formatAccessExpiry(expiresAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SetupHeader(
          title: 'Patient access',
          subtitle:
              'Share this code with the patient so they can scan or enter it to connect their Alera account.',
          bottomSpacing: 16,
        ),
        AleraCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PATIENT ACCESS CODE',
                style: AleraTypography.label.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      accessCode,
                      key: const Key('issued-access-code'),
                      style: AleraTypography.sectionTitle.copyWith(
                        fontSize: 22,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CopyChip(onTap: () => _copy(context)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Expires $expiry',
                style: AleraTypography.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AleraColors.surfaceTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    key: const Key('access-code-qr'),
                    data: buildPatientAccessQrPayload(accessCode: accessCode),
                    size: 150,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Scan this QR code or enter the code manually.',
                  textAlign: TextAlign.center,
                  style: AleraTypography.body.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              _ValidityStrip(expiry: expiry),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.content_copy_outlined,
                      label: 'Copy code',
                      onTap: () => _copy(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: onShare,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Status card for states with no code on screen: connected, expired,
/// invitation pending, unavailable.
class PatientAccessNoticeContent extends StatelessWidget {
  final IconData? icon;

  /// A branded SVG (e.g. the shared "success" checkmark used in Active
  /// Alerts' empty state), used instead of [icon] when set.
  final String? iconAsset;
  final String title;
  final String message;
  final String? detail;

  const PatientAccessNoticeContent({
    super.key,
    this.icon,
    this.iconAsset,
    required this.title,
    required this.message,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SetupHeader(title: 'Patient access', bottomSpacing: 16),
        AleraCard(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                if (iconAsset != null)
                  AleraSvgIcon(assetPath: iconAsset!, width: 56, height: 56)
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AleraColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 28, color: AleraColors.primary),
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AleraTypography.sectionTitle.copyWith(
                    fontSize: 16,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AleraTypography.body.copyWith(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: AleraTypography.body.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AleraColors.primarySoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: AleraColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AleraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AleraTypography.body.copyWith(
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CopyChip extends StatelessWidget {
  final VoidCallback onTap;
  const _CopyChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AleraColors.primarySoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.content_copy_outlined,
                size: 16,
                color: AleraColors.textPrimary,
              ),
              SizedBox(width: 6),
              Text(
                'Copy',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AleraColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValidityStrip extends StatelessWidget {
  final String expiry;
  const _ValidityStrip({required this.expiry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AleraColors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StripItem(
                icon: Icons.schedule_outlined,
                title: 'Valid for 24 hours',
                subtitle: 'Expires $expiry',
              ),
            ),
            const VerticalDivider(
              width: 20,
              thickness: 1,
              color: AleraColors.divider,
            ),
            const Expanded(
              child: _StripItem(
                icon: Icons.verified_user_outlined,
                title: 'One-time use only',
                subtitle: 'This code can only be used once.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _StripItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AleraColors.primarySoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AleraColors.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AleraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AleraTypography.body.copyWith(fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AleraColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AleraColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
