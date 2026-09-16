import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/caregiver/domain/models/care_recipient.dart';

void showPatientContactFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<void> openPatientContactApp(
  BuildContext context, {
  required CareRecipient careRecipient,
  required String scheme,
  required String appLabel,
  String? message,
}) async {
  final phoneNumber = careRecipient.phoneNumber?.trim();

  if (phoneNumber == null || phoneNumber.isEmpty) {
    showPatientContactFeedback(
      context,
      'No phone number is saved for ${careRecipient.name}.',
    );
    return;
  }

  final Uri uri;

  if (scheme == 'sms' && message != null && message.trim().isNotEmpty) {
    uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message.trim()},
    );
  } else {
    uri = Uri(scheme: scheme, path: phoneNumber);
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      showPatientContactFeedback(context, 'Unable to open the $appLabel app.');
    }
  } catch (_) {
    if (context.mounted) {
      showPatientContactFeedback(context, 'Unable to open the $appLabel app.');
    }
  }
}
