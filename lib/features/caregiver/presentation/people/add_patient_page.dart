import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_spacing.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../../../design_system/widgets/alera_section_card.dart';
import '../../data/api/caregiver_patient_api_data_source.dart';
import '../../data/api/dto/patient_dto.dart';

class AddPatientPage extends StatefulWidget {
  final CaregiverPatientDataSource dataSource;
  final String? householdCode;
  final FutureOr<void> Function(PatientCreatedResponse) onPatientCreated;

  const AddPatientPage({
    super.key,
    required this.dataSource,
    required this.householdCode,
    required this.onPatientCreated,
  });

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _conditions = TextEditingController();
  final _medications = TextEditingController();
  final _heartRate = TextEditingController();
  final _spo2 = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _birthdate;
  String? _sex;
  bool _submitting = false;
  bool _issuing = false;
  String? _error;
  PatientCreatedResponse? _created;
  PatientAccessCodeResponse? _issued;

  @override
  void dispose() {
    _clearAccessCode();
    for (final controller in [
      _name,
      _phone,
      _address,
      _emergencyName,
      _emergencyPhone,
      _conditions,
      _medications,
      _heartRate,
      _spo2,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearAccessCode() => _issued = null;

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: _birthdate ?? DateTime(now.year - 65),
    );
    if (picked != null && mounted) setState(() => _birthdate = picked);
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await widget.dataSource.createPatient(
        CreatePatientRequest(
          fullName: _name.text,
          birthdate: _birthdate,
          sex: _sex,
          phoneNumber: _phone.text,
          addressOrRoom: _address.text,
          emergencyContactName: _emergencyName.text,
          emergencyContactPhone: _emergencyPhone.text,
          knownConditions: _conditions.text,
          medications: _medications.text,
          baselineHeartRate: num.tryParse(_heartRate.text),
          baselineSpo2: num.tryParse(_spo2.text),
          monitoringNotes: _notes.text,
        ),
      );
      if (!mounted) return;
      await widget.onPatientCreated(response);
      setState(() => _created = response);
    } on CaregiverPatientApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to create the patient. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _issueAccessCode() async {
    if (_issuing || _issued != null || _created == null) return;
    setState(() {
      _issuing = true;
      _error = null;
    });
    try {
      final response = await widget.dataSource.createAccessCode(
        _created!.patientId,
      );
      if (mounted) setState(() => _issued = response);
    } on CaregiverPatientApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to issue an access code. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  String get _qrPayload =>
      buildPatientAccessQrPayload(accessCode: _issued!.accessCode);

  void _done() {
    _clearAccessCode();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) => _clearAccessCode(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_created == null ? 'Add Patient' : 'Patient Created'),
        ),
        body: SafeArea(
          child: _created == null
              ? _buildForm()
              : _issued == null
              ? _buildCreated()
              : _buildAccessCode(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AleraSpacing.medium),
        children: [
          Text('Patient details', style: AleraTypography.pageTitle),
          const SizedBox(height: 8),
          Text(
            'Only full name is required. Add what is available now.',
            style: AleraTypography.body,
          ),
          const SizedBox(height: 16),
          AleraSectionCard(
            title: 'Personal',
            child: Column(
              children: [
                _field(
                  _name,
                  'Full name *',
                  key: const Key('patient-name-field'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the patient’s full name.';
                    }
                    if (value.trim().length > 150) {
                      return 'Use 150 characters or fewer.';
                    }
                    return null;
                  },
                ),
                _gap,
                InkWell(
                  key: const Key('birthdate-field'),
                  onTap: _pickBirthdate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Birthdate',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _birthdate == null
                          ? 'Select date'
                          : _formatDate(_birthdate!),
                    ),
                  ),
                ),
                _gap,
                DropdownButtonFormField<String>(
                  key: const Key('sex-field'),
                  initialValue: _sex,
                  decoration: const InputDecoration(labelText: 'Sex'),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _sex = value),
                ),
                _gap,
                _field(
                  _phone,
                  'Phone number',
                  keyboardType: TextInputType.phone,
                  validator: _patientPhoneValidator,
                ),
                _gap,
                _field(_address, 'Address or room', maxLines: 2),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AleraSectionCard(
            title: 'Emergency Contact',
            child: Column(
              children: [
                _field(
                  _emergencyName,
                  'Contact name',
                  validator: (value) => (value?.trim().length ?? 0) > 150
                      ? 'Use 150 characters or fewer.'
                      : null,
                ),
                _gap,
                _field(
                  _emergencyPhone,
                  'Contact phone',
                  keyboardType: TextInputType.phone,
                  validator: (value) => (value?.trim().length ?? 0) > 30
                      ? 'Use 30 characters or fewer.'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AleraSectionCard(
            title: 'Care Information',
            child: Column(
              children: [
                _field(_conditions, 'Known conditions', maxLines: 2),
                _gap,
                _field(_medications, 'Medications', maxLines: 2),
                _gap,
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _heartRate,
                        'Baseline heart rate',
                        key: const Key('heart-rate-field'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => _numberError(
                          value,
                          minExclusive: 0,
                          label: 'heart rate',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        _spo2,
                        'Baseline SpO₂',
                        key: const Key('spo2-field'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => _numberError(
                          value,
                          min: 0,
                          max: 100,
                          label: 'SpO₂',
                        ),
                      ),
                    ),
                  ],
                ),
                _gap,
                _field(_notes, 'Monitoring notes', maxLines: 3),
              ],
            ),
          ),
          if (_error != null) _errorView,
          const SizedBox(height: 16),
          AleraButton(
            label: _submitting ? 'Creating…' : 'Create Patient',
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildCreated() => _resultLayout([
    const Icon(Icons.check_circle, color: AleraColors.success, size: 72),
    const SizedBox(height: 16),
    Text(
      'Patient created',
      style: AleraTypography.pageTitle,
      textAlign: TextAlign.center,
    ),
    const SizedBox(height: 8),
    Text(
      '${_created!.fullName} now appears in People.',
      style: AleraTypography.body,
      textAlign: TextAlign.center,
    ),
    if (_error != null) _errorView,
    const SizedBox(height: 24),
    AleraButton(
      label: _issuing ? 'Generating…' : 'Generate Access Code',
      onPressed: _issuing ? null : _issueAccessCode,
    ),
    const SizedBox(height: 10),
    AleraButton(
      label: 'Done',
      variant: AleraButtonVariant.secondary,
      onPressed: _done,
    ),
  ]);

  Widget _buildAccessCode() {
    final householdCode = widget.householdCode;
    return _resultLayout([
      Text('Patient access', style: AleraTypography.pageTitle),
      const SizedBox(height: 8),
      Text(
        'Valid for 24 hours and usable only once.',
        style: AleraTypography.body,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      if (householdCode != null) ...[
        Text('Household code', style: AleraTypography.label),
        SelectableText(householdCode, style: AleraTypography.sectionTitle),
        const SizedBox(height: 12),
      ],
      Text('Access code', style: AleraTypography.label),
      SelectableText(
        _issued!.accessCode,
        key: const Key('issued-access-code'),
        style: AleraTypography.pageTitle,
      ),
      const SizedBox(height: 12),
      Text(
        'Expires ${_formatDateTime(_issued!.expiresAt)}',
        style: AleraTypography.body,
      ),
      const SizedBox(height: 20),
      Semantics(
        label: 'Patient access QR code',
        child: QrImageView(
          key: const Key('access-code-qr'),
          data: _qrPayload,
          size: 220,
        ),
      ),
      const SizedBox(height: 20),
      AleraButton(
        label: 'Share',
        icon: Icons.share,
        onPressed: () => SharePlus.instance.share(
          ShareParams(
            text:
                'Join ${_created!.fullName} on Alera. One-time patient code: ${_issued!.accessCode}\nThis invitation expires ${_formatDateTime(_issued!.expiresAt)}.',
          ),
        ),
      ),
      const SizedBox(height: 10),
      AleraButton(
        label: 'Done',
        variant: AleraButtonVariant.secondary,
        onPressed: _done,
      ),
    ]);
  }

  Widget _resultLayout(List<Widget> children) => ListView(
    padding: const EdgeInsets.all(AleraSpacing.large),
    children: [const SizedBox(height: 24), ...children],
  );

  Widget get _errorView => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Text(
      _error!,
      key: const Key('patient-error'),
      style: const TextStyle(color: AleraColors.critical),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    Key? key,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    key: key,
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(labelText: label),
    inputFormatters: keyboardType == TextInputType.phone
        ? [FilteringTextInputFormatter.deny(RegExp(r'[\n]'))]
        : null,
  );

  static const Widget _gap = SizedBox(height: 12);

  String? _patientPhoneValidator(String? value) =>
      (value?.trim().length ?? 0) > 11 ? 'Use 11 characters or fewer.' : null;

  String? _numberError(
    String? value, {
    double? min,
    double? minExclusive,
    double? max,
    required String label,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    if (number == null) return 'Enter a valid $label.';
    if (minExclusive != null && number <= minExclusive) {
      return 'Enter a $label greater than ${minExclusive.toStringAsFixed(0)}.';
    }
    if (min != null && number < min || max != null && number > max) {
      return 'Enter a $label from ${min!.toStringAsFixed(0)} to ${max!.toStringAsFixed(0)}.';
    }
    return null;
  }
}

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${_formatDate(local)} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String buildPatientAccessQrPayload({required String accessCode}) => jsonEncode({
  'type': 'alera_patient_access',
  'version': 2,
  'access_code': accessCode,
});
