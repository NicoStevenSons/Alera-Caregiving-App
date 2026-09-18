import 'package:flutter/widgets.dart';

/// Localisation seam for status labels.
///
/// The repository has no `flutter_localizations` / `AppLocalizations` stack
/// yet. Rather than block the status system on that work, domain adapters call
/// `AleraStatusLabels.of(context)` at build time and read a named getter. When
/// the l10n stack lands, [AleraStatusLabels.of] switches to reading
/// `AppLocalizations.of(context)` and no call site changes.
///
/// Labels are resolved at render time, never at descriptor construction, so no
/// adapter needs a [BuildContext] before build.
@immutable
class AleraStatusLabels {
  const AleraStatusLabels();

  /// Resolve labels for [context].
  ///
  /// The parameter is unused today and deliberately retained: it is the hook
  /// the l10n migration needs, and keeping it now avoids touching every adapter
  /// later.
  static AleraStatusLabels of(BuildContext context) {
    return const AleraStatusLabels();
  }

  // Alert severity.
  String get alertCritical => 'Critical';
  String get alertWarning => 'Warning';
  String get alertInfo => 'Info';

  // Reminder state.
  String get reminderOverdue => 'Overdue';
  String get reminderSnoozed => 'Snoozed';
  String get reminderScheduled => 'Scheduled';
  String get reminderCompleted => 'Completed';

  // Device state.
  String get deviceOnline => 'Online';
  String get deviceLowBattery => 'Low battery';
  String get deviceOffline => 'Offline';

  // Patient state.
  String get patientActive => 'Active';
  String get patientPendingAccess => 'Pending access';
  String get patientInactive => 'Inactive';

  // Vital / trend labels.
  String get vitalElevated => 'Elevated';
  String get vitalNormal => 'Normal';
  String get vitalLow => 'Low';
}
