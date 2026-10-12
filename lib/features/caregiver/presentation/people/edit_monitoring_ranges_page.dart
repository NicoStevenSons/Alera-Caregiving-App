import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_chevron_app_bar.dart';
import '../../../../design_system/widgets/alera_text_field.dart';
import '../../data/api/caregiver_patient_api_data_source.dart';
import '../../data/api/dto/patient_dto.dart';
import 'widgets/patient_setup_widgets.dart';

/// Alera's built-in monitoring ranges, used by "Use Alera defaults".
const int kDefaultHrMin = 60;
const int kDefaultHrMax = 100;
const int kDefaultSpo2Min = 95;

/// Short summary of a patient's ranges for the Edit Patient row.
String monitoringRangesSummary(PatientDetailDto patient) {
  if (patient.thresholdMode != PatientThresholdMode.custom) {
    return 'Alera defaults';
  }
  final max = patient.usualSpo2Max;
  final spo2 = max == null
      ? 'SpO₂ min ${patient.usualSpo2Min}%'
      : 'SpO₂ ${patient.usualSpo2Min}–$max%';
  return 'Heart rate ${patient.normalHrMin}–${patient.normalHrMax} bpm · $spo2';
}

/// Changes a patient's heart-rate and SpO₂ monitoring ranges through the
/// existing monitoring-settings endpoint. Pops with the saved
/// [MonitoringSettingsResponse]. "Use Alera defaults" saves the built-in
/// ranges (60–100 bpm, SpO₂ min 95%, no maximum).
class EditMonitoringRangesPage extends StatefulWidget {
  final PatientDetailDto patient;
  final CaregiverPatientDataSource dataSource;

  const EditMonitoringRangesPage({
    super.key,
    required this.patient,
    required this.dataSource,
  });

  @override
  State<EditMonitoringRangesPage> createState() =>
      _EditMonitoringRangesPageState();
}

class _EditMonitoringRangesPageState extends State<EditMonitoringRangesPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hrMin;
  late final TextEditingController _hrMax;
  late final TextEditingController _spo2Min;
  late final TextEditingController _spo2Max;
  late bool _custom;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _custom = p.thresholdMode == PatientThresholdMode.custom;
    _hrMin = TextEditingController(text: '${p.normalHrMin}');
    _hrMax = TextEditingController(text: '${p.normalHrMax}');
    _spo2Min = TextEditingController(text: '${p.usualSpo2Min}');
    _spo2Max = TextEditingController(text: p.usualSpo2Max?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in [_hrMin, _hrMax, _spo2Min, _spo2Max]) {
      c.dispose();
    }
    super.dispose();
  }

  UpdateMonitoringSettingsRequest get _request => _custom
      ? UpdateMonitoringSettingsRequest(
          normalHrMin: int.parse(_hrMin.text.trim()),
          normalHrMax: int.parse(_hrMax.text.trim()),
          usualSpo2Min: int.parse(_spo2Min.text.trim()),
          usualSpo2Max: _spo2Max.text.trim().isEmpty
              ? null
              : int.parse(_spo2Max.text.trim()),
        )
      : const UpdateMonitoringSettingsRequest(
          normalHrMin: kDefaultHrMin,
          normalHrMax: kDefaultHrMax,
          usualSpo2Min: kDefaultSpo2Min,
          usualSpo2Max: null,
        );

  String? _whole(String? x, int min, int max, String label) {
    if (x == null || x.trim().isEmpty) return 'Enter $label.';
    final n = int.tryParse(x.trim());
    if (n == null) return 'Enter $label as a whole number.';
    if (n < min || n > max) return 'Enter $label from $min to $max.';
    return null;
  }

  String? _optionalWhole(String? x, int min, int max, String label) =>
      x == null || x.trim().isEmpty ? null : _whole(x, min, max, label);

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _error = null);
    if (_custom) {
      if (!_formKey.currentState!.validate()) return;
      if (int.parse(_hrMin.text.trim()) > int.parse(_hrMax.text.trim())) {
        setState(
          () => _error = 'Heart rate minimum must not be above the maximum.',
        );
        return;
      }
      if (_spo2Max.text.trim().isNotEmpty &&
          int.parse(_spo2Min.text.trim()) > int.parse(_spo2Max.text.trim())) {
        setState(() => _error = 'SpO₂ minimum must not be above the maximum.');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final saved = await widget.dataSource.updateMonitoringSettings(
        widget.patient.patientId,
        _request,
      );
      if (mounted) Navigator.of(context).pop(saved);
    } on CaregiverPatientApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = failure.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Unable to save the ranges. Please try again.';
        });
      }
    }
  }

  Widget _rangeSection(String title, Widget min, Widget max) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AleraTypography.rowTitle),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: min),
          const SizedBox(width: 12),
          Expanded(child: max),
        ],
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label,
    String hint,
    String suffix,
    Key key,
    String? Function(String?) validator,
  ) => AleraTextField(
    controller: controller,
    label: label,
    hint: hint,
    fieldKey: key,
    suffixText: suffix,
    enabled: !_saving,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: validator,
    bottomSpacing: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AleraChevronAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  key: const Key('edit-monitoring-form'),
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  children: [
                    SetupHeader(
                      title: 'Monitoring ranges',
                      subtitle:
                          'Choose when ${widget.patient.fullName}’s readings '
                          'need attention.',
                    ),
                    SetupOptionCard(
                      key: const Key('monitoring-default-option'),
                      selected: !_custom,
                      title: 'Use Alera defaults',
                      lines: const [
                        'Heart rate: 60–100 bpm',
                        'SpO₂: minimum 95%',
                      ],
                      onTap: () => setState(() {
                        if (!_saving) _custom = false;
                      }),
                    ),
                    const SizedBox(height: 12),
                    SetupOptionCard(
                      key: const Key('monitoring-custom-option'),
                      selected: _custom,
                      title: 'Set custom ranges',
                      lines: const [
                        'Define monitoring limits for this patient.',
                      ],
                      onTap: () => setState(() {
                        if (!_saving) _custom = true;
                      }),
                    ),
                    if (_custom) ...[
                      const SizedBox(height: 24),
                      _rangeSection(
                        'Heart rate (bpm)',
                        _field(
                          _hrMin,
                          'Minimum',
                          '60',
                          'bpm',
                          const Key('monitoring-hr-min-field'),
                          (x) => _whole(x, 1, 999, 'a minimum heart rate'),
                        ),
                        _field(
                          _hrMax,
                          'Maximum',
                          '100',
                          'bpm',
                          const Key('monitoring-hr-max-field'),
                          (x) => _whole(x, 1, 999, 'a maximum heart rate'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _rangeSection(
                        'Blood oxygen (SpO₂)',
                        _field(
                          _spo2Min,
                          'Minimum',
                          '95',
                          '%',
                          const Key('monitoring-spo2-min-field'),
                          (x) => _whole(x, 0, 100, 'a minimum SpO₂'),
                        ),
                        _field(
                          _spo2Max,
                          'Maximum (optional)',
                          'Enter value',
                          '%',
                          const Key('monitoring-spo2-max-field'),
                          (x) => _optionalWhole(x, 0, 100, 'SpO₂ maximum'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    AleraCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info,
                            size: 22,
                            color: AleraColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Critical safety limits',
                                  style: AleraTypography.bodyStrong,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Alera’s built-in critical safety overrides '
                                  'still apply even when custom monitoring '
                                  'ranges are used.',
                                  style: AleraTypography.caption.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        key: const Key('edit-monitoring-error'),
                        style: AleraTypography.errorText,
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: AleraButton(
                          label: 'Cancel',
                          variant: AleraButtonVariant.lightPill,
                          height: 44,
                          onPressed: _saving
                              ? null
                              : () => Navigator.maybePop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AleraButton(
                          key: const Key('edit-monitoring-save'),
                          label: _saving
                              ? 'Saving…'
                              : _error != null
                              ? 'Try again'
                              : 'Save ranges',
                          variant: AleraButtonVariant.pill,
                          height: 44,
                          onPressed: _saving ? null : _save,
                        ),
                      ),
                    ],
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
