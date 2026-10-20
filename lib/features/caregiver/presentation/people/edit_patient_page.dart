import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_dialog.dart';
import '../../../../design_system/widgets/alera_patient_avatar.dart';
import '../../../../design_system/widgets/alera_text_field.dart';
import '../../data/api/caregiver_patient_api_data_source.dart';
import '../../data/api/caregiver_patient_archive_data_source.dart';
import '../../data/api/caregiver_patient_edit_data_source.dart';
import '../../data/api/dto/patient_dto.dart';
import '../../data/patients/edit_patient_controller.dart';
import 'edit_monitoring_ranges_page.dart';
import 'widgets/backup_caregiver_fields.dart';
import 'widgets/patient_photo_picker.dart';
import 'widgets/patient_setup_widgets.dart';
import 'widgets/relationship_field.dart';
import '../../../../design_system/alera_spacing.dart';
import '../../../../design_system/alera_typography.dart';

/// Edits an existing patient's profile and the signed-in caregiver's
/// relationship label. Monitoring ranges are not part of the profile save;
/// they open their own screen from the "Monitoring ranges" row and save
/// through the monitoring-settings endpoint. The same screen holds the
/// confirmed "Archive patient" action.
///
/// Pops with an [EditPatientResult] after a successful save, after archiving,
/// or when the caregiver changed the monitoring ranges and then went back.
class EditPatientPage extends StatefulWidget {
  final PatientDetailDto patient;
  final CaregiverPatientEditDataSource editDataSource;
  final CaregiverPatientDataSource photoDataSource;
  final CaregiverPatientArchiveDataSource archiveDataSource;
  final PatientPhotoPickerFn? pickPhoto;

  const EditPatientPage({
    super.key,
    required this.patient,
    required this.editDataSource,
    required this.photoDataSource,
    this.archiveDataSource = const UnavailablePatientArchiveDataSource(),
    this.pickPhoto,
  });

  @override
  State<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends State<EditPatientPage> {
  final _formKey = GlobalKey<FormState>();
  late final EditPatientController _controller;

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _birthDay;
  late final TextEditingController _birthMonth;
  late final TextEditingController _birthYear;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyPhone;
  late final TextEditingController _backupName;
  late final TextEditingController _backupPhone;
  late final TextEditingController _conditions;
  late final TextEditingController _medications;
  late final TextEditingController _notes;
  late final TextEditingController _relationship;
  String? _sex;

  PatientPhotoUpload? _newPhoto;
  String? _photoError;
  bool _birthdateTouched = false;

  /// The patient as last known on this screen: the one passed in, updated
  /// when the monitoring ranges are saved.
  late PatientDetailDto _patient;
  bool _rangesChanged = false;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _patient = p;
    _controller = EditPatientController(
      patientId: p.patientId,
      editDataSource: widget.editDataSource,
      photoDataSource: widget.photoDataSource,
    )..addListener(_changed);
    _name = TextEditingController(text: p.fullName);
    _phone = TextEditingController(text: p.phoneNumber ?? '');
    _address = TextEditingController(text: p.addressOrRoom ?? '');
    final b = p.birthdate;
    _birthDay = TextEditingController(
      text: b == null ? '' : b.day.toString().padLeft(2, '0'),
    );
    _birthMonth = TextEditingController(
      text: b == null ? '' : b.month.toString().padLeft(2, '0'),
    );
    _birthYear = TextEditingController(
      text: b == null ? '' : b.year.toString().padLeft(4, '0'),
    );
    _emergencyName = TextEditingController(text: p.emergencyContactName ?? '');
    _emergencyPhone = TextEditingController(
      text: p.emergencyContactPhone ?? '',
    );
    _backupName = TextEditingController(text: p.backupCaregiverName ?? '');
    _backupPhone = TextEditingController(text: p.backupCaregiverPhone ?? '');
    _conditions = TextEditingController(text: p.knownConditions ?? '');
    _medications = TextEditingController(text: p.medications ?? '');
    _notes = TextEditingController(text: p.monitoringNotes ?? '');
    _relationship = TextEditingController(text: p.relationshipLabel ?? '');
    _sex = const {'MALE', 'FEMALE', 'OTHER'}.contains(p.sex) ? p.sex : null;
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_changed)
      ..dispose();
    for (final c in [
      _name,
      _phone,
      _address,
      _birthDay,
      _birthMonth,
      _birthYear,
      _emergencyName,
      _emergencyPhone,
      _backupName,
      _backupPhone,
      _conditions,
      _medications,
      _notes,
      _relationship,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  DateTime? get _birthdate {
    final d = int.tryParse(_birthDay.text.trim());
    final m = int.tryParse(_birthMonth.text.trim());
    final y = int.tryParse(_birthYear.text.trim());
    if (d == null || m == null || y == null) return null;
    if (y < 1900 || m < 1 || m > 12 || d < 1) return null;
    final date = DateTime(y, m, d);
    if (date.year != y || date.month != m || date.day != d) return null;
    if (date.isAfter(DateTime.now())) return null;
    return date;
  }

  String? _birthdateError() {
    final parts = [
      _birthDay,
      _birthMonth,
      _birthYear,
    ].map((c) => c.text.trim()).toList();
    if (parts.every((p) => p.isEmpty)) return null;
    if (parts.any((p) => p.isEmpty)) return 'Enter the day, month and year.';
    if (parts[2].length < 4) return 'Enter a 4-digit year.';
    return _birthdate == null ? 'Enter a valid birthdate.' : null;
  }

  UpdatePatientRequest get _request => UpdatePatientRequest(
    fullName: _name.text,
    birthdate: _birthdate,
    sex: _sex,
    phoneNumber: _phone.text,
    addressOrRoom: _address.text,
    emergencyContactName: _emergencyName.text,
    emergencyContactPhone: _emergencyPhone.text,
    knownConditions: _conditions.text,
    medications: _medications.text,
    monitoringNotes: _notes.text,
    backupCaregiverName: _backupName.text,
    backupCaregiverPhone: _backupPhone.text,
    relationshipLabel: _relationship.text,
  );

  Future<void> _choosePhoto() async {
    try {
      final picked = await (widget.pickPhoto ?? pickAndCropPatientPhoto)();
      if (picked == null || !mounted) return;
      setState(() {
        _newPhoto = picked;
        _photoError = null;
      });
    } on PatientPhotoException catch (e) {
      if (mounted) setState(() => _photoError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _photoError = 'Unable to open that photo. Try another.');
      }
    }
  }

  Future<bool> _save() async {
    if (_controller.isSaving) return false;
    setState(() => _birthdateTouched = true);
    if (!_formKey.currentState!.validate()) return false;
    final ok = await _controller.save(_request, photo: _newPhoto);
    if (ok && mounted) {
      _rangesChanged = false;
      Navigator.of(context).pop(_controller.result);
    }
    return ok;
  }

  /// Confirms, then saves the patient with no backup contact (both fields
  /// sent as null). If the save fails the previous contact is put back.
  Future<void> _removeBackup() async {
    if (_controller.isSaving) return;
    final confirmed = await showAleraConfirmDialog(
      context,
      icon: Icons.person_remove,
      title: 'Remove backup caregiver?',
      message:
          '${_backupName.text.trim()} will no longer get text messages when '
          '${_patient.fullName} has a critical alert.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final oldName = _backupName.text;
    final oldPhone = _backupPhone.text;
    setState(() {
      _backupName.clear();
      _backupPhone.clear();
    });
    final ok = await _save();
    if (!ok && mounted) {
      setState(() {
        _backupName.text = oldName;
        _backupPhone.text = oldPhone;
      });
    }
  }

  Future<void> _openRanges() async {
    final saved = await Navigator.of(context).push<MonitoringSettingsResponse>(
      MaterialPageRoute<MonitoringSettingsResponse>(
        builder: (_) => EditMonitoringRangesPage(
          patient: _patient,
          dataSource: widget.photoDataSource,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    setState(() {
      _patient = _patient.withMonitoringSettings(saved);
      _rangesChanged = true;
    });
  }

  Future<void> _confirmArchive() async {
    var busy = false;
    String? error;
    final archived = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AleraDialog(
          key: const Key('archive-patient-dialog'),
          icon: Icons.archive,
          destructive: true,
          title: 'Archive ${_patient.fullName}?',
          message:
              'This patient will be archived and removed from your People '
              'list.',
          busy: busy,
          errorText: error,
          cancelLabel: 'Cancel',
          confirmLabel: busy ? 'Archiving…' : 'Archive',
          onCancel: () => Navigator.pop(dialogContext, false),
          onConfirm: () async {
            setDialogState(() {
              busy = true;
              error = null;
            });
            try {
              await widget.archiveDataSource.archivePatient(_patient.patientId);
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            } on CaregiverPatientApiFailure catch (failure) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  busy = false;
                  error = failure.message;
                });
              }
            } catch (_) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  busy = false;
                  error = 'Unable to archive this patient. Please try again.';
                });
              }
            }
          },
        ),
      ),
    );
    if (archived == true && mounted) {
      _rangesChanged = false;
      Navigator.of(
        context,
      ).pop(EditPatientResult(patient: _patient, archived: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = _controller.isSaving;
    final error = _controller.errorMessage;
    return PopScope<Object?>(
      canPop: !_rangesChanged,
      onPopInvokedWithResult: (didPop, _) {
        // Ranges are saved on their own screen; hand them back so the detail
        // page does not show stale values if the profile form is abandoned.
        if (!didPop) {
          Navigator.of(context).pop(EditPatientResult(patient: _patient));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 44,
          leadingWidth: 56,
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.chevron_left, size: 28),
            color: AleraColors.mutedIcon,
            onPressed: saving ? null : () => Navigator.maybePop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    key: const Key('edit-patient-form'),
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    children: [
                      const SetupHeader(
                        title: 'Edit patient',
                        subtitle:
                            'Update this person’s details and monitoring '
                            'ranges.',
                      ),
                      _photoSection(saving),
                      const SizedBox(height: 20),
                      AleraTextField(
                        controller: _name,
                        label: 'Full name',
                        hint: 'Enter patient’s full name',
                        fieldKey: const Key('edit-name-field'),
                        required: true,
                        enabled: !saving,
                        validator: (x) => x == null || x.trim().isEmpty
                            ? 'Enter the patient’s full name.'
                            : x.trim().length > 150
                            ? 'Use 150 characters or fewer.'
                            : null,
                      ),
                      RelationshipField(
                        controller: _relationship,
                        enabled: !saving,
                      ),
                      AleraTextField(
                        controller: _phone,
                        label: 'Phone number',
                        hint: 'Enter patient’s phone number',
                        fieldKey: const Key('edit-phone-field'),
                        enabled: !saving,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [LengthLimitingTextInputFormatter(11)],
                      ),
                      AleraTextField(
                        controller: _address,
                        label: 'Address or room',
                        hint: 'Enter patient’s address or room',
                        fieldKey: const Key('edit-address-field'),
                        enabled: !saving,
                      ),
                      _birthdateField(saving),
                      _sexField(saving),
                      AleraTextField(
                        controller: _emergencyName,
                        label: 'Emergency contact name',
                        hint: 'Enter emergency contact’s full name',
                        fieldKey: const Key('edit-emergency-name-field'),
                        enabled: !saving,
                        validator: (x) => (x?.length ?? 0) > 150
                            ? 'Use 150 characters or fewer.'
                            : null,
                      ),
                      AleraTextField(
                        controller: _emergencyPhone,
                        label: 'Emergency contact phone',
                        hint: 'Enter emergency contact’s phone number',
                        fieldKey: const Key('edit-emergency-phone-field'),
                        enabled: !saving,
                        keyboardType: TextInputType.phone,
                        validator: (x) => (x?.length ?? 0) > 30
                            ? 'Use 30 characters or fewer.'
                            : null,
                      ),
                      BackupCaregiverFields(
                        nameController: _backupName,
                        phoneController: _backupPhone,
                        enabled: !saving,
                        onRemove: _removeBackup,
                      ),
                      AleraTextField(
                        controller: _conditions,
                        label: 'Known conditions (Separate with comma)',
                        hint: 'e.g. Hypertension, Diabetes',
                        fieldKey: const Key('edit-conditions-field'),
                        enabled: !saving,
                      ),
                      AleraTextField(
                        controller: _medications,
                        label: 'Medications',
                        hint: 'Enter patient’s medications',
                        fieldKey: const Key('edit-medications-field'),
                        enabled: !saving,
                      ),
                      AleraTextField(
                        controller: _notes,
                        label: 'Monitoring notes',
                        hint: 'Add any notes for monitoring',
                        fieldKey: const Key('edit-notes-field'),
                        enabled: !saving,
                        maxLines: 3,
                      ),
                      _monitoringRow(saving),
                      _archiveRow(saving),
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
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          error,
                          key: const Key('edit-patient-error'),
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
                            onPressed: saving
                                ? null
                                : () => Navigator.maybePop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AleraButton(
                            key: const Key('edit-patient-save'),
                            label: saving
                                ? 'Saving…'
                                : error != null
                                ? 'Try again'
                                : 'Save changes',
                            variant: AleraButtonVariant.pill,
                            height: 44,
                            onPressed: saving ? null : _save,
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
      ),
    );
  }

  Widget _monitoringRow(bool saving) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: AleraCard(
      key: const Key('edit-monitoring-ranges'),
      onTap: saving ? null : _openRanges,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          const Icon(Icons.monitor_heart, size: 22, color: AleraColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monitoring ranges',
                  style: AleraTypography.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(
                  monitoringRangesSummary(_patient),
                  key: const Key('edit-monitoring-summary'),
                  style: AleraTypography.caption,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 22,
            color: AleraColors.mutedChevron,
          ),
        ],
      ),
    ),
  );

  Widget _archiveRow(bool saving) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Center(
      child: TextButton.icon(
        key: const Key('edit-archive-patient'),
        onPressed: saving ? null : _confirmArchive,
        style: TextButton.styleFrom(foregroundColor: AleraColors.critical),
        icon: const Icon(Icons.archive, size: 20),
        label: const Text(
          'Archive patient',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );

  Widget _photoSection(bool saving) {
    final photo = _newPhoto;
    return Center(
      child: Column(
        children: [
          photo == null
              ? AleraPatientAvatar(
                  key: const Key('edit-patient-photo-current'),
                  name: _name.text.isEmpty
                      ? widget.patient.fullName
                      : _name.text,
                  photoUrl: widget.patient.profilePhotoUrl,
                  radius: 46,
                )
              : CircleAvatar(
                  key: const Key('edit-patient-photo-preview'),
                  radius: 46,
                  backgroundImage: MemoryImage(photo.bytes),
                ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('edit-choose-photo'),
            onPressed: saving ? null : _choosePhoto,
            style: TextButton.styleFrom(foregroundColor: AleraColors.primary),
            icon: const Icon(Icons.photo_library, size: 18),
            label: Text(
              photo == null ? 'Change photo' : 'Choose a different photo',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          if (_photoError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _photoError!,
                key: const Key('edit-photo-error'),
                textAlign: TextAlign.center,
                style: AleraTypography.errorText,
              ),
            ),
        ],
      ),
    );
  }

  Widget _birthdateField(bool saving) => FormField<String>(
    key: const Key('edit-birthdate-field'),
    validator: (_) => _birthdateError(),
    builder: (state) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AleraFieldLabel('Birthdate'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _birthBox(
                  _birthDay,
                  'DD',
                  2,
                  state,
                  const Key('edit-birth-day-field'),
                  saving,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _birthBox(
                  _birthMonth,
                  'MM',
                  2,
                  state,
                  const Key('edit-birth-month-field'),
                  saving,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _birthBox(
                  _birthYear,
                  'YYYY',
                  4,
                  state,
                  const Key('edit-birth-year-field'),
                  saving,
                ),
              ),
            ],
          ),
          if (state.hasError && _birthdateTouched)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                state.errorText!,
                key: const Key('edit-birthdate-error'),
                style: AleraTypography.errorText,
              ),
            ),
        ],
      ),
    ),
  );

  Widget _birthBox(
    TextEditingController controller,
    String hint,
    int length,
    FormFieldState<String> state,
    Key key,
    bool saving,
  ) => TextField(
    key: key,
    controller: controller,
    enabled: !saving,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(length),
    ],
    style: const TextStyle(fontSize: 13, color: AleraColors.textPrimary),
    cursorColor: AleraColors.primary,
    decoration: aleraInputDecoration(hint: hint),
    onChanged: (_) {
      if (state.hasError) state.validate();
    },
  );

  Widget _sexField(bool saving) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AleraFieldLabel('Sex'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const Key('edit-sex-field'),
          initialValue: _sex,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AleraColors.fieldHint,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(AleraSpacing.cardRadius),
          style: const TextStyle(fontSize: 13, color: AleraColors.textPrimary),
          decoration: aleraInputDecoration(hint: 'Select patient’s sex'),
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
          ],
          onChanged: saving ? null : (x) => setState(() => _sex = x),
        ),
      ],
    ),
  );
}
