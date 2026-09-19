import 'package:alera/design_system/alera_colors.dart';
import 'package:alera/features/caregiver/domain/models/caregiver_alert.dart';
import 'package:alera/features/caregiver/presentation/widgets/caregiver_alert_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CaregiverAlert alert({
    required CaregiverAlertMetric metric,
    CaregiverAlertSeverity severity = CaregiverAlertSeverity.warning,
  }) {
    return CaregiverAlert(
      id: 'alert',
      careRecipientId: 'patient',
      title: 'Alert',
      description: '',
      severity: severity,
      metric: metric,
      status: CaregiverAlertStatus.active,
      reading: 0,
      threshold: null,
      unit: '',
      triggerDuration: null,
      detectedAt: DateTime(2026, 9, 19),
      timeline: const [],
    );
  }

  group('accent colors', () {
    test('warning health alerts use warning yellow', () {
      expect(
        CaregiverAlertPresentation.accentColor(
          alert(metric: CaregiverAlertMetric.heartRate),
        ),
        AleraColors.warning,
      );
      expect(
        CaregiverAlertPresentation.accentColor(
          alert(metric: CaregiverAlertMetric.activity),
        ),
        AleraColors.warning,
      );
    });

    test('critical health alerts use critical red', () {
      expect(
        CaregiverAlertPresentation.accentColor(
          alert(
            metric: CaregiverAlertMetric.spo2,
            severity: CaregiverAlertSeverity.critical,
          ),
        ),
        AleraColors.critical,
      );
      expect(
        CaregiverAlertPresentation.accentColor(
          alert(
            metric: CaregiverAlertMetric.sleep,
            severity: CaregiverAlertSeverity.critical,
          ),
        ),
        AleraColors.critical,
      );
    });

    test('system alerts use information blue', () {
      expect(
        CaregiverAlertPresentation.accentColor(
          alert(metric: CaregiverAlertMetric.system),
        ),
        AleraColors.information,
      );
    });

    test('battery alerts stay purple', () {
      expect(
        CaregiverAlertPresentation.accentColor(
          alert(metric: CaregiverAlertMetric.watchBattery),
        ),
        AleraColors.battery,
      );
    });
  });

  group('type badges', () {
    test('system uses the info badge', () {
      expect(
        CaregiverAlertPresentation.badgeAssetPath(CaregiverAlertMetric.system),
        'alera-figma-assets/assets/icons/mini_status/info.svg',
      );
    });

    test('battery uses the dedicated battery badge', () {
      expect(
        CaregiverAlertPresentation.badgeAssetPath(
          CaregiverAlertMetric.watchBattery,
        ),
        'alera-figma-assets/assets/icons/mini_status/battery.svg',
      );
    });

    test('activity and sleep retain their own type badges', () {
      expect(
        CaregiverAlertPresentation.badgeAssetPath(
          CaregiverAlertMetric.activity,
        ),
        'alera-figma-assets/assets/icons/mini_status/activity.svg',
      );
      expect(
        CaregiverAlertPresentation.badgeAssetPath(CaregiverAlertMetric.sleep),
        'alera-figma-assets/assets/icons/mini_status/sleep.svg',
      );
    });
  });
}
