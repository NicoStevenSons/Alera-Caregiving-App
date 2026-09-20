import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/status/alera_status_chip.dart';
import '../../../../design_system/status/adapters/device_status_chip.dart';
import '../../../../design_system/status/adapters/patient_access_status_chip.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../design_system/widgets/alera_confirmation_dialog.dart';
import '../../../../design_system/widgets/alera_section_card.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../../../design_system/widgets/alera_text_field.dart';
import '../../data/api/caregiver_patient_api_data_source.dart';
import '../../data/api/dto/patient_dto.dart';
import 'patient_access_setup_page.dart';
import 'widgets/patient_access_views.dart';
import 'widgets/patient_setup_widgets.dart';

export 'widgets/patient_access_views.dart' show buildPatientAccessQrPayload;

enum _Step { intro, personal, care, monitoring, review, created, pairing, code }

class PatientPhotoSelection {
  final Uint8List bytes;
  final String filename;
  final String contentType;

  const PatientPhotoSelection({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });
}

typedef PatientPhotoPicker = Future<PatientPhotoSelection?> Function();

class AddPatientPage extends StatefulWidget {
  final CaregiverPatientDataSource dataSource;
  final Future<PatientDetailDto> Function(String patientId)? loadPatientDetail;
  final String? householdCode;
  final FutureOr<void> Function(PatientCreatedResponse) onPatientCreated;
  final PatientPhotoPicker? pickPatientPhoto;
  const AddPatientPage({
    super.key,
    required this.dataSource,
    this.loadPatientDetail,
    required this.householdCode,
    required this.onPatientCreated,
    this.pickPatientPhoto,
  });
  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage>
    with WidgetsBindingObserver {
  final p = GlobalKey<FormState>(),
      c = GlobalKey<FormState>(),
      m = GlobalKey<FormState>();
  final name = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController(),
      birthDay = TextEditingController(),
      birthMonth = TextEditingController(),
      birthYear = TextEditingController(),
      emergencyName = TextEditingController(),
      emergencyPhone = TextEditingController(),
      conditions = TextEditingController(),
      medications = TextEditingController(),
      hr = TextEditingController(),
      spo2 = TextEditingController(),
      notes = TextEditingController(),
      hrMin = TextEditingController(text: '60'),
      hrMax = TextEditingController(text: '100'),
      spo2Min = TextEditingController(text: '95'),
      spo2Max = TextEditingController();
  _Step step = _Step.intro;
  _Step? returnTo;
  String? sex, error;
  Uint8List? _profilePhotoBytes;
  String? _profilePhotoFilename;
  String? _profilePhotoContentType;
  String? _profilePhotoError;
  bool custom = false,
      busy = false,
      issuing = false,
      called = false,
      settingsFailed = false,
      photoUploadFailed = false;
  PatientCreatedResponse? created;
  PatientAccessCodeResponse? issued;
  Timer? _pollTimer;
  bool _polling = false;
  bool _accessConnected = false;
  bool _accessExpired = false;
  bool _foreground = true;

  /// Birthdate assembled from the DD / MM / YYYY boxes, or null when the
  /// boxes are empty or don't form a real, past date.
  DateTime? get birthdate {
    final d = int.tryParse(birthDay.text.trim());
    final mo = int.tryParse(birthMonth.text.trim());
    final y = int.tryParse(birthYear.text.trim());
    if (d == null || mo == null || y == null) return null;
    if (y < 1900 || mo < 1 || mo > 12 || d < 1) return null;
    final date = DateTime(y, mo, d);
    if (date.year != y || date.month != mo || date.day != d) return null;
    if (date.isAfter(DateTime.now())) return null;
    return date;
  }

  String? birthdateError() {
    final parts = [
      birthDay,
      birthMonth,
      birthYear,
    ].map((e) => e.text.trim()).toList();
    if (parts.every((e) => e.isEmpty)) return null;
    if (parts.any((e) => e.isEmpty)) return 'Enter the day, month and year.';
    if (parts[2].length < 4) return 'Enter a 4-digit year.';
    return birthdate == null ? 'Enter a valid birthdate.' : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    for (final x in [
      name,
      phone,
      address,
      birthDay,
      birthMonth,
      birthYear,
      emergencyName,
      emergencyPhone,
      conditions,
      medications,
      hr,
      spo2,
      notes,
      hrMin,
      hrMax,
      spo2Min,
      spo2Max,
    ]) {
      x.dispose();
    }
    issued = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _startPollingIfEligible();
    } else {
      _stopPolling();
    }
  }

  bool get _codeExpired =>
      issued != null && !DateTime.now().toUtc().isBefore(issued!.expiresAt);
  bool get _canPoll =>
      mounted &&
      _foreground &&
      step == _Step.code &&
      issued != null &&
      !_accessConnected &&
      !_accessExpired &&
      !_codeExpired &&
      widget.loadPatientDetail != null;

  void _startPollingIfEligible() {
    if (issued != null && _codeExpired) {
      _expireAccessCode();
      return;
    }
    if (!_canPoll || _pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    _poll();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll() async {
    if (_codeExpired) {
      _expireAccessCode();
      return;
    }
    if (!_canPoll || _polling) return;
    _polling = true;
    try {
      final detail = await widget.loadPatientDetail!(created!.patientId);
      if (!mounted || step != _Step.code) return;
      if (detail.patientAccessStatus.status == PatientAccessState.connected) {
        _stopPolling();
        setState(() => _accessConnected = true);
      } else if (_codeExpired) {
        _expireAccessCode();
      }
    } catch (_) {
      // Keep the invitation visible; the shared session/API layer handles 401s.
    } finally {
      _polling = false;
    }
  }

  void _expireAccessCode() {
    _stopPolling();
    if (mounted && !_accessExpired) setState(() => _accessExpired = true);
  }

  void go(_Step x) {
    if (step == _Step.code && x != _Step.code) _stopPolling();
    if (x == _Step.review) returnTo = null;
    setState(() {
      error = null;
      step = x;
    });
    if (x == _Step.code) _startPollingIfEligible();
  }

  void back() {
    if (created != null) {
      if (step == _Step.pairing || step == _Step.code) go(_Step.created);
      return;
    }
    if (returnTo != null) {
      returnTo = null;
      go(_Step.review);
      return;
    }
    final x = {
      _Step.personal: _Step.intro,
      _Step.care: _Step.personal,
      _Step.monitoring: _Step.care,
      _Step.review: _Step.monitoring,
    }[step];
    if (x == null) {
      Navigator.pop(context);
    } else {
      go(x);
    }
  }

  CreatePatientRequest get request => CreatePatientRequest(
    fullName: name.text,
    birthdate: birthdate,
    sex: sex,
    phoneNumber: phone.text,
    addressOrRoom: address.text,
    emergencyContactName: emergencyName.text,
    emergencyContactPhone: emergencyPhone.text,
    knownConditions: conditions.text,
    medications: medications.text,
    baselineHeartRate: num.tryParse(hr.text),
    baselineSpo2: num.tryParse(spo2.text),
    monitoringNotes: notes.text,
  );
  UpdateMonitoringSettingsRequest get settings =>
      UpdateMonitoringSettingsRequest(
        normalHrMin: int.parse(hrMin.text),
        normalHrMax: int.parse(hrMax.text),
        usualSpo2Min: int.parse(spo2Min.text),
        usualSpo2Max: spo2Max.text.trim().isEmpty
            ? null
            : int.parse(spo2Max.text),
      );
  String msg(Object e, String fallback) =>
      e is CaregiverPatientApiFailure ? e.message : fallback;

  Future<void> pickProfilePhoto() async {
    if (widget.pickPatientPhoto != null) {
      final selected = await widget.pickPatientPhoto!();
      if (selected == null || !mounted) return;

      _applyProfilePhotoSelection(
        bytes: selected.bytes,
        filename: selected.filename,
        contentType: selected.contentType,
      );
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop photo',

          // Alera top bar
          toolbarColor: const Color(0xFFF9F5FF),
          toolbarWidgetColor: const Color(0xFF3F365C),

          // Main crop area
          backgroundColor: const Color(0xFFF5F0FA),
          dimmedLayerColor: const Color(0x99000000),

          // Alera purple instead of orange
          activeControlsWidgetColor: const Color(0xFFA884E8),

          // Keep the square crop fixed
          lockAspectRatio: true,
          showCropGrid: true,

          // IMPORTANT: keep controls visible
          hideBottomControls: false,

          aspectRatioPresets: [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: 'Crop photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
      ],
    );
    if (cropped == null) return;

    final croppedFile = XFile(cropped.path);
    final bytes = await croppedFile.readAsBytes();
    if (!mounted) return;

    final contentType = _profilePhotoMimeType(croppedFile);
    if (contentType == null) {
      setState(() {
        _profilePhotoError = 'Choose a JPEG, PNG, or WebP image.';
      });
      return;
    }

    _applyProfilePhotoSelection(
      bytes: bytes,
      filename: croppedFile.name,
      contentType: contentType,
    );
  }

  void _applyProfilePhotoSelection({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) {
    if (bytes.length > 5 * 1024 * 1024) {
      setState(() {
        _profilePhotoError = 'Choose a photo that is 5 MB or smaller.';
      });
      return;
    }

    const allowedTypes = {'image/jpeg', 'image/png', 'image/webp'};
    if (!allowedTypes.contains(contentType.toLowerCase())) {
      setState(() {
        _profilePhotoError = 'Choose a JPEG, PNG, or WebP image.';
      });
      return;
    }

    setState(() {
      _profilePhotoBytes = bytes;
      _profilePhotoFilename = filename;
      _profilePhotoContentType = contentType.toLowerCase();
      _profilePhotoError = null;
      photoUploadFailed = false;
    });
  }

  void removeProfilePhoto() {
    setState(() {
      _profilePhotoBytes = null;
      _profilePhotoFilename = null;
      _profilePhotoContentType = null;
      _profilePhotoError = null;
      photoUploadFailed = false;
    });
  }

  String? _profilePhotoMimeType(XFile file) {
    final mime = file.mimeType?.toLowerCase();
    if (mime == 'image/jpeg' || mime == 'image/png' || mime == 'image/webp') {
      return mime;
    }

    final lower = file.name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  Future<void> _uploadProfilePhoto() async {
    final bytes = _profilePhotoBytes;
    final filename = _profilePhotoFilename;
    final contentType = _profilePhotoContentType;
    final patient = created;

    if (bytes == null ||
        filename == null ||
        contentType == null ||
        patient == null) {
      return;
    }

    final result = await widget.dataSource.uploadProfilePhoto(
      patient.patientId,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );

    created = PatientCreatedResponse(
      patientId: patient.patientId,
      userId: patient.userId,
      householdId: patient.householdId,
      accountStatus: patient.accountStatus,
      assignment: patient.assignment,
      fullName: patient.fullName,
      birthdate: patient.birthdate,
      sex: patient.sex,
      phoneNumber: patient.phoneNumber,
      addressOrRoom: patient.addressOrRoom,
      profilePhotoUrl: result.profilePhotoUrl,
      emergencyContactName: patient.emergencyContactName,
      emergencyContactPhone: patient.emergencyContactPhone,
      knownConditions: patient.knownConditions,
      medications: patient.medications,
      baselineHeartRate: patient.baselineHeartRate,
      baselineSpo2: patient.baselineSpo2,
      monitoringNotes: patient.monitoringNotes,
      createdAt: patient.createdAt,
    );
  }

  Future<void> retryPhotoUpload() async {
    if (created == null || busy || _profilePhotoBytes == null) return;
    setState(() {
      busy = true;
      _profilePhotoError = null;
    });
    try {
      await _uploadProfilePhoto();
      photoUploadFailed = false;
      await widget.onPatientCreated(created!);
    } catch (e) {
      photoUploadFailed = true;
      _profilePhotoError = msg(
        e,
        'The patient was created, but the photo could not be uploaded.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create() async {
    if (busy || created != null) return;
    setState(() => busy = true);
    try {
      created = await widget.dataSource.createPatient(request);
      if (custom) {
        try {
          await widget.dataSource.updateMonitoringSettings(
            created!.patientId,
            settings,
          );
        } catch (e) {
          settingsFailed = true;
          error = msg(e, 'Profile exists but custom settings were not saved.');
        }
      }

      if (_profilePhotoBytes != null) {
        try {
          await _uploadProfilePhoto();
          photoUploadFailed = false;
        } catch (e) {
          photoUploadFailed = true;
          _profilePhotoError = msg(
            e,
            'The patient was created, but the photo could not be uploaded.',
          );
        }
      }

      if (!called) {
        called = true;
        await widget.onPatientCreated(created!);
      }

      if (mounted) setState(() => step = _Step.created);
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              error = msg(e, 'Unable to create the patient. Please try again.'),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> retrySettings() async {
    if (created == null || busy) return;
    setState(() => busy = true);
    try {
      await widget.dataSource.updateMonitoringSettings(
        created!.patientId,
        settings,
      );
      if (mounted) {
        setState(() {
          settingsFailed = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = msg(e, 'Custom settings were not saved.'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openPatientAccess() async {
    if (created == null || widget.loadPatientDetail == null) return;
    final result = await Navigator.push<PatientAccessSetupResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAccessSetupPage(
          patientId: created!.patientId,
          patientName: created!.fullName,
          patientAccess: const PatientAccessStatus(
            status: PatientAccessState.notConnected,
            statusValue: 'NOT_CONNECTED',
            pendingAccessCodeId: null,
            pendingExpiresAt: null,
            connectedAt: null,
          ),
          dataSource: widget.dataSource,
          loadPatientDetail: widget.loadPatientDetail!,
        ),
      ),
    );
    if (result == PatientAccessSetupResult.changed && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> issue() async {
    if (created == null || issuing || issued != null) return;
    setState(() => issuing = true);
    try {
      final x = await widget.dataSource.createAccessCode(created!.patientId);
      if (mounted) {
        setState(() {
          issued = x;
          _accessConnected = false;
          _accessExpired = false;
        });
      }
      go(_Step.code);
    } catch (e) {
      if (mounted) {
        setState(() => error = msg(e, 'Unable to issue an access code.'));
      }
    } finally {
      if (mounted) setState(() => issuing = false);
    }
  }

  Future<void> finish() async {
    final ok = await showAleraConfirmationDialog(
      context,
      icon: Icons.watch_later_outlined,
      title: 'Finish setup for now?',
      message:
          'The patient remains saved but cannot send readings until connected.',
      cancelLabel: 'Continue setup',
      confirmLabel: 'Finish for now',
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  Future<void> confirm() async {
    final ok = await showAleraConfirmationDialog(
      context,
      icon: Icons.person_add_alt_outlined,
      title: 'Create ${name.text.trim()}’s profile?',
      message:
          'The patient will be added using the reviewed information and connection can happen afterward.',
      cancelLabel: 'Review again',
      confirmLabel: 'Create patient',
    );
    if (ok == true) await create();
  }

  void edit(_Step x) => setState(() {
    returnTo = _Step.review;
    error = null;
    step = x;
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: step == _Step.intro,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) back();
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
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.chevron_left, size: 28),
          color: const Color(0xFFB4AEC2),
          onPressed: back,
        ),
      ),
      body: SafeArea(
        child: switch (step) {
          _Step.intro => intro(),
          _Step.personal => personal(),
          _Step.care => care(),
          _Step.monitoring => monitoring(),
          _Step.review => review(),
          _Step.created => createdView(),
          _Step.pairing => pairing(),
          _Step.code => code(),
        },
      ),
    ),
  );

  // ---------------------------------------------------------------------
  // Frame helpers
  // ---------------------------------------------------------------------

  Widget frame({required List<Widget> children, Widget? bottom}) => Column(
    children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.all(24), children: children),
      ),
      if (bottom != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: bottom,
        ),
    ],
  );

  Widget bottomBar(List<Widget> actions, {bool showError = true}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showError && error != null)
        Padding(padding: const EdgeInsets.only(bottom: 12), child: err),
      ...actions,
    ],
  );

  Widget get err => Text(
    error!,
    key: const Key('patient-error'),
    style: const TextStyle(fontSize: 12, color: AleraColors.critical),
  );

  Widget primaryButton(String label, VoidCallback? onPressed) => AleraButton(
    label: label,
    variant: AleraButtonVariant.pill,
    height: 44,
    onPressed: onPressed,
  );

  Widget secondaryButton(String label, VoidCallback? onPressed) => AleraButton(
    label: label,
    variant: AleraButtonVariant.lightPill,
    height: 44,
    onPressed: onPressed,
  );

  // ---------------------------------------------------------------------
  // Intro (no Figma frame: built from the same info-row motif as the
  // Patient access explainer)
  // ---------------------------------------------------------------------

  Widget intro() => frame(
    children: [
      const SetupHeader(
        title: 'Add someone to your care',
        subtitle:
            'Create a profile, configure monitoring, and optionally connect patient access.',
        bottomSpacing: 24,
      ),
      AleraCard(
        padding: const EdgeInsets.all(20),
        child: const Column(
          children: [
            _IntroRow(
              icon: Icons.person_outline,
              title: 'Personal information',
              subtitle: 'Name, phone number, address and birthdate.',
            ),
            SizedBox(height: 20),
            _IntroRow(
              icon: Icons.description_outlined,
              title: 'Care information',
              subtitle: 'Emergency contact, conditions and medications.',
            ),
            SizedBox(height: 20),
            _IntroRow(
              icon: Icons.monitor_heart_outlined,
              title: 'Monitoring settings',
              subtitle: 'Use Alera defaults or set custom ranges.',
            ),
            SizedBox(height: 20),
            _IntroRow(
              icon: Icons.people_outline,
              title: 'Patient access',
              subtitle: 'Connect the patient after their profile is created.',
            ),
          ],
        ),
      ),
    ],
    bottom: bottomBar([primaryButton('Start setup', () => go(_Step.personal))]),
  );

  // ---------------------------------------------------------------------
  // Personal Information (Figma wireframe 1)
  // ---------------------------------------------------------------------

  Widget personal() => Form(
    key: p,
    child: frame(
      children: [
        const SetupHeader(
          title: 'Personal Information',
          subtitle: 'Fill in information about your patient.',
          bottomSpacing: 20,
        ),
        Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    key: const Key('patient-profile-photo-preview'),
                    radius: 46,
                    backgroundColor: AleraColors.primarySoft,
                    backgroundImage: _profilePhotoBytes == null
                        ? null
                        : MemoryImage(_profilePhotoBytes!),
                    child: _profilePhotoBytes == null
                        ? const Icon(
                            Icons.person_outline,
                            size: 42,
                            color: AleraColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        key: const Key('choose-patient-photo'),
                        onPressed: pickProfilePhoto,
                        style: TextButton.styleFrom(
                          foregroundColor: AleraColors.primary,
                        ),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _profilePhotoBytes == null
                              ? 'Choose photo'
                              : 'Change photo',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_profilePhotoBytes != null)
                        TextButton(
                          key: const Key('remove-patient-photo'),
                          onPressed: removeProfilePhoto,
                          style: TextButton.styleFrom(
                            foregroundColor: AleraColors.textSecondary,
                          ),
                          child: const Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_profilePhotoError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _profilePhotoError!,
                        key: const Key('patient-photo-error'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AleraColors.critical,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            field(
              name,
              'Full name',
              'Enter patient’s full name',
              key: const Key('patient-name-field'),
              required: true,
              v: (x) => x == null || x.trim().isEmpty
                  ? 'Enter the patient’s full name.'
                  : x.trim().length > 150
                  ? 'Use 150 characters or fewer.'
                  : null,
            ),
            field(
              phone,
              'Phone number',
              'Enter patient’s phone number',
              phone: true,
              v: (x) =>
                  (x?.length ?? 0) > 11 ? 'Use 11 characters or fewer.' : null,
            ),
            field(address, 'Address', 'Enter patient’s address or room'),
            birthdateField(),
            sexField(),
          ],
        ),
      ],
      bottom: bottomBar([
        SetupButtonRow(
          onBack: back,
          onNext: () {
            if (p.currentState!.validate()) go(returnTo ?? _Step.care);
          },
        ),
      ]),
    ),
  );

  Widget birthdateField() => FormField<String>(
    key: const Key('birthdate-field'),
    validator: (_) => birthdateError(),
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
                child: birthBox(
                  birthDay,
                  'DD',
                  2,
                  state,
                  key: const Key('birth-day-field'),
                  next: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: birthBox(
                  birthMonth,
                  'MM',
                  2,
                  state,
                  key: const Key('birth-month-field'),
                  next: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: birthBox(
                  birthYear,
                  'YYYY',
                  4,
                  state,
                  key: const Key('birth-year-field'),
                ),
              ),
            ],
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                state.errorText!,
                key: const Key('birthdate-error'),
                style: const TextStyle(
                  fontSize: 11,
                  color: AleraColors.critical,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget birthBox(
    TextEditingController controller,
    String hint,
    int length,
    FormFieldState<String> state, {
    required Key key,
    bool next = false,
  }) => TextField(
    key: key,
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(length),
    ],
    style: const TextStyle(fontSize: 13, color: AleraColors.textPrimary),
    cursorColor: AleraColors.primary,
    decoration: aleraInputDecoration(hint: hint),
    onChanged: (value) {
      if (state.hasError) state.validate();
      if (next && value.length == length) FocusScope.of(context).nextFocus();
    },
  );

  Widget sexField() => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AleraFieldLabel('Sex'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const Key('sex-field'),
          initialValue: sex,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AleraColors.fieldHint,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(fontSize: 13, color: AleraColors.textPrimary),
          decoration: aleraInputDecoration(hint: 'Select patient’s sex'),
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
          ],
          onChanged: (x) => setState(() => sex = x),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------
  // Care Information (Figma wireframe 2)
  // ---------------------------------------------------------------------

  Widget care() => Form(
    key: c,
    child: frame(
      children: [
        const SetupHeader(
          title: 'Care Information',
          subtitle:
              'Baseline readings are reference values and do not control alert thresholds.',
          bottomSpacing: 20,
        ),
        Column(
          children: [
            field(
              emergencyName,
              'Emergency contact name',
              'Enter emergency contact’s full name',
              v: (x) => (x?.length ?? 0) > 150
                  ? 'Use 150 characters or fewer.'
                  : null,
            ),
            field(
              emergencyPhone,
              'Emergency contact phone',
              'Enter emergency contact’s phone number',
              keyboard: TextInputType.phone,
              v: (x) =>
                  (x?.length ?? 0) > 30 ? 'Use 30 characters or fewer.' : null,
            ),
            field(
              conditions,
              'Known conditions (Separate with comma)',
              'e.g. Hypertension, Diabetes',
            ),
            field(medications, 'Medications', 'Enter patient’s medications'),
            field(
              hr,
              'Baseline heart rate',
              'Enter baseline heart rate',
              key: const Key('heart-rate-field'),
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bpm',
              v: (x) => number(x, 0, null, true, 'heart rate'),
            ),
            field(
              spo2,
              'Baseline SpO₂',
              'Enter baseline SpO₂',
              key: const Key('spo2-field'),
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              suffix: '%',
              v: (x) => number(x, 0, 100, false, 'SpO₂'),
            ),
            field(
              notes,
              'Monitoring notes',
              'Add any notes for monitoring',
              maxLines: 3,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: () {
              if (c.currentState!.validate()) go(returnTo ?? _Step.monitoring);
            },
            style: TextButton.styleFrom(foregroundColor: AleraColors.primary),
            child: const Text(
              'Skip for now',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
      bottom: bottomBar([
        SetupButtonRow(
          onBack: back,
          onNext: () {
            if (c.currentState!.validate()) go(returnTo ?? _Step.monitoring);
          },
        ),
      ]),
    ),
  );

  // ---------------------------------------------------------------------
  // Monitoring Settings (Figma frame 3)
  // ---------------------------------------------------------------------

  void continueFromMonitoring() {
    if (!m.currentState!.validate()) return;
    if (custom) {
      if (int.parse(hrMin.text) > int.parse(hrMax.text)) {
        setState(
          () => error = 'Heart rate minimum must not be above the maximum.',
        );
        return;
      }
      if (spo2Max.text.trim().isNotEmpty &&
          int.parse(spo2Min.text) > int.parse(spo2Max.text)) {
        setState(() => error = 'SpO₂ minimum must not be above the maximum.');
        return;
      }
    }
    go(returnTo ?? _Step.review);
  }

  Widget monitoring() => Form(
    key: m,
    child: frame(
      children: [
        const SetupHeader(
          title: 'Monitoring Settings',
          subtitle:
              'Choose how Alera should determine when this patient’s readings need attention.',
        ),
        SetupOptionCard(
          key: const Key('default-monitoring-option'),
          selected: !custom,
          title: 'Use Alera defaults',
          lines: const ['Heart rate: 60–100 bpm', 'SpO₂: minimum 95%'],
          onTap: () => setState(() => custom = false),
        ),
        const SizedBox(height: 12),
        SetupOptionCard(
          key: const Key('custom-monitoring-option'),
          selected: custom,
          title: 'Set custom ranges',
          lines: const ['Define monitoring limits for this patient.'],
          onTap: () => setState(() => custom = true),
        ),
        if (custom) ...[
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              rangeSection('Heart rate (bpm)', [
                rangeField(
                  hrMin,
                  'Minimum',
                  '60',
                  'bpm',
                  const Key('hr-min-field'),
                  (x) => requiredInteger(x, 1, 999, 'a minimum heart rate'),
                ),
                rangeField(
                  hrMax,
                  'Maximum',
                  '100',
                  'bpm',
                  const Key('hr-max-field'),
                  (x) => requiredInteger(x, 1, 999, 'a maximum heart rate'),
                ),
              ]),
              const SizedBox(height: 20),
              rangeSection('Blood oxygen (SpO₂)', [
                rangeField(
                  spo2Min,
                  'Minimum',
                  '95',
                  '%',
                  const Key('spo2-min-field'),
                  (x) => requiredInteger(x, 0, 100, 'a minimum SpO₂'),
                ),
                rangeField(
                  spo2Max,
                  'Maximum (optional)',
                  'Enter value',
                  '%',
                  const Key('spo2-max-field'),
                  (x) => integer(x, 0, 100, 'SpO₂ maximum'),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          AleraCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 22,
                  color: AleraColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Critical safety limits',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AleraColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Alera’s built-in critical safety overrides still apply even when custom monitoring ranges are used.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AleraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
      bottom: bottomBar([
        SetupButtonRow(onBack: back, onNext: continueFromMonitoring),
      ]),
    ),
  );

  Widget rangeSection(String title, List<Widget> fields) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AleraColors.textPrimary,
        ),
      ),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: fields[0]),
          const SizedBox(width: 12),
          Expanded(child: fields[1]),
        ],
      ),
    ],
  );

  Widget rangeField(
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
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: validator,
    bottomSpacing: 0,
  );

  // ---------------------------------------------------------------------
  // Review (Figma frame 4) + confirmation dialog (Figma frame 5)
  // ---------------------------------------------------------------------

  bool get hasCareInformation => [
    emergencyName,
    emergencyPhone,
    conditions,
    medications,
    hr,
    spo2,
    notes,
  ].any((x) => x.text.trim().isNotEmpty);

  String get monitoringRangeSummary {
    if (!custom) return 'HR 60–100 bpm  ·  SpO₂ ≥ 95%';
    final spo2Upper = spo2Max.text.trim();
    final spo2Text = spo2Upper.isEmpty
        ? 'SpO₂ ≥ ${spo2Min.text.trim()}%'
        : 'SpO₂ ${spo2Min.text.trim()}–$spo2Upper%';
    return 'HR ${hrMin.text.trim()}–${hrMax.text.trim()} bpm  ·  $spo2Text';
  }

  /// [AleraSectionCard] with a smaller heading, used only on the Review
  /// step: four stacked section cards read better with a compact title
  /// than the app's usual 20px section heading.
  Widget reviewSectionCard({
    required String title,
    required Widget child,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) => AleraSectionCard(
    title: title,
    actionLabel: actionLabel,
    onActionPressed: onActionPressed,
    titleStyle: AleraTypography.sectionTitle.copyWith(fontSize: 16),
    child: child,
  );

  Widget review() => frame(
    children: [
      const SetupHeader(
        title: 'Review',
        subtitle:
            'Make sure everything looks right before creating this patient.',
      ),
      if (_profilePhotoBytes != null) ...[
        Center(
          child: CircleAvatar(
            key: const Key('review-patient-photo'),
            radius: 42,
            backgroundImage: MemoryImage(_profilePhotoBytes!),
          ),
        ),
        const SizedBox(height: 16),
      ],
      reviewSectionCard(
        title: 'Personal Information',
        actionLabel: 'Edit',
        onActionPressed: () => edit(_Step.personal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SetupLabeledValue(label: 'Full name', value: name.text),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SetupLabeledValue(
                    label: 'Birthdate',
                    value: birthdate == null
                        ? null
                        : formatBirthdate(birthdate!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SetupLabeledValue(
                    label: 'Phone number',
                    value: phone.text,
                  ),
                ),
              ],
            ),
            if (address.text.trim().isNotEmpty || sex != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SetupLabeledValue(
                      label: 'Address',
                      value: address.text,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SetupLabeledValue(
                      label: 'Sex',
                      value: switch (sex) {
                        'MALE' => 'Male',
                        'FEMALE' => 'Female',
                        'OTHER' => 'Other',
                        _ => null,
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      reviewSectionCard(
        title: 'Care Information',
        actionLabel: 'Edit',
        onActionPressed: () => edit(_Step.care),
        child: hasCareInformation
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (emergencyName.text.trim().isNotEmpty ||
                      emergencyPhone.text.trim().isNotEmpty)
                    careLine(
                      'Emergency contact',
                      [
                        emergencyName.text.trim(),
                        emergencyPhone.text.trim(),
                      ].where((e) => e.isNotEmpty).join(' · '),
                    ),
                  if (conditions.text.trim().isNotEmpty)
                    careLine('Known conditions', conditions.text.trim()),
                  if (medications.text.trim().isNotEmpty)
                    careLine('Medications', medications.text.trim()),
                  if (hr.text.trim().isNotEmpty)
                    careLine('Baseline heart rate', '${hr.text.trim()} bpm'),
                  if (spo2.text.trim().isNotEmpty)
                    careLine('Baseline SpO₂', '${spo2.text.trim()}%'),
                  if (notes.text.trim().isNotEmpty)
                    careLine('Monitoring notes', notes.text.trim()),
                ],
              )
            : const Text(
                'No care information added.',
                style: TextStyle(
                  fontSize: 14,
                  color: AleraColors.textSecondary,
                ),
              ),
      ),
      const SizedBox(height: 12),
      reviewSectionCard(
        title: 'Monitoring Settings',
        actionLabel: 'Edit',
        onActionPressed: () => edit(_Step.monitoring),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              custom ? 'Custom ranges' : 'Alera defaults',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AleraColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              monitoringRangeSummary,
              style: AleraTypography.body.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      reviewSectionCard(
        title: 'Connection',
        child: Column(
          children: const [
            _ConnectionRow(
              label: 'Patient access',
              chip: PatientAccessStatusChip(PatientAccessState.notConnected),
            ),
            SizedBox(height: 12),
            _ConnectionRow(
              label: 'Smartwatch',
              chip: DeviceStatusChip(
                PatientDeviceConnectionStatus.notConnected,
              ),
            ),
          ],
        ),
      ),
    ],
    bottom: bottomBar([
      SetupButtonRow(
        onBack: back,
        onNext: busy ? null : confirm,
        nextLabel: busy ? 'Creating…' : 'Create patient',
      ),
    ]),
  );

  Widget careLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SetupLabeledValue(label: label, value: value),
  );

  // ---------------------------------------------------------------------
  // Created (Figma frame 6)
  // ---------------------------------------------------------------------

  Widget createdView() => frame(
    children: [
      const SizedBox(height: 8),
      const Center(
        child: AleraSvgIcon(
          assetPath:
              'alera-figma-assets/assets/icons/status/no-active-alerts.svg',
          width: 64,
          height: 64,
          semanticLabel: 'Patient added',
        ),
      ),
      const SizedBox(height: 20),
      SetupHeader(
        title: '${created!.fullName} has been added',
        subtitle:
            'The patient profile is ready. You can connect patient access now or do this later.',
        centered: true,
      ),
      if (photoUploadFailed) ...[
        AleraCard(
          color: AleraColors.critical.withValues(alpha: 0.06),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_profilePhotoError != null)
                Text(
                  _profilePhotoError!,
                  key: const Key('patient-photo-upload-error'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AleraColors.critical,
                  ),
                ),
              const SizedBox(height: 12),
              AleraButton(
                label: busy ? 'Uploading…' : 'Retry photo upload',
                variant: AleraButtonVariant.pill,
                height: 40,
                onPressed: busy ? null : retryPhotoUpload,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (settingsFailed) ...[
        AleraCard(
          color: AleraColors.critical.withValues(alpha: 0.06),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null) err,
              if (error != null) const SizedBox(height: 12),
              AleraButton(
                label: 'Retry settings',
                variant: AleraButtonVariant.pill,
                height: 40,
                onPressed: busy ? null : retrySettings,
              ),
              const SizedBox(height: 8),
              AleraButton(
                label: 'Use Alera defaults',
                variant: AleraButtonVariant.lightPill,
                height: 40,
                onPressed: () => setState(() {
                  settingsFailed = false;
                  custom = false;
                  error = null;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      AleraCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _CreatedRow(
              icon: Icons.description_outlined,
              title: 'Profile',
              trailing: const Text(
                'Created',
                style: TextStyle(
                  fontSize: 13,
                  color: AleraColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _CreatedRow(
              icon: Icons.monitor_heart_outlined,
              title: 'Monitoring',
              subtitle: monitoringRangeSummary.replaceAll('  ·  ', ' • '),
              trailing: settingsFailed
                  ? const Text(
                      'Not saved',
                      style: TextStyle(
                        fontSize: 13,
                        color: AleraColors.critical,
                      ),
                    )
                  : Text(
                      custom ? 'Custom' : 'Defaults',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AleraColors.textSecondary,
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            const _CreatedRow(
              icon: Icons.people_outline,
              title: 'Patient access',
              trailing: PatientAccessStatusChip(
                PatientAccessState.notConnected,
                size: AleraStatusChipSize.small,
              ),
            ),
            const SizedBox(height: 18),
            const _CreatedRow(
              iconAsset:
                  'alera-figma-assets/assets/icons/devices/watch-monitoring.svg',
              title: 'Smartwatch',
              trailing: DeviceStatusChip(
                PatientDeviceConnectionStatus.notConnected,
                size: AleraStatusChipSize.small,
              ),
            ),
          ],
        ),
      ),
    ],
    bottom: bottomBar([
      primaryButton(
        'Connect patient access',
        widget.loadPatientDetail == null
            ? () => go(_Step.pairing)
            : openPatientAccess,
      ),
      const SizedBox(height: 12),
      secondaryButton('Finish for now', finish),
    ], showError: false),
  );

  // ---------------------------------------------------------------------
  // Patient access (Figma frames 7 + 8)
  // ---------------------------------------------------------------------

  Widget pairing() => frame(
    children: const [PatientAccessIntroContent()],
    bottom: bottomBar([
      primaryButton(
        issuing ? 'Generating…' : 'Generate access code',
        issuing ? null : issue,
      ),
      const SizedBox(height: 12),
      secondaryButton('Do this later', finish),
    ]),
  );

  Widget code() {
    final connected = _accessConnected;
    final expired = _accessExpired;
    final Widget content = connected
        ? PatientAccessNoticeContent(
            iconAsset:
                'alera-figma-assets/assets/icons/status/no-active-alerts.svg',
            title: '${created!.fullName}’s patient access is connected',
            message: 'The patient can now sign in with their Alera account.',
          )
        : expired
        ? const PatientAccessNoticeContent(
            icon: Icons.timer_off_outlined,
            title: 'The invitation expired.',
            message:
                'You can generate a new code later from the patient’s profile.',
          )
        : PatientAccessCodeContent(
            accessCode: issued!.accessCode,
            expiresAt: issued!.expiresAt,
            onShare: () => SharePlus.instance.share(
              ShareParams(
                text:
                    '${created!.fullName}\nAccess code: ${issued!.accessCode}\n'
                    'Expires ${formatAccessExpiry(issued!.expiresAt)}',
              ),
            ),
          );
    return frame(
      children: [content],
      bottom: bottomBar([primaryButton('Done', () => Navigator.pop(context))]),
    );
  }

  // ---------------------------------------------------------------------
  // Field helpers + validators
  // ---------------------------------------------------------------------

  Widget field(
    TextEditingController x,
    String label,
    String hint, {
    Key? key,
    bool required = false,
    bool phone = false,
    TextInputType? keyboard,
    String? suffix,
    int maxLines = 1,
    String? Function(String?)? v,
  }) => AleraTextField(
    controller: x,
    label: label,
    hint: hint,
    fieldKey: key,
    required: required,
    suffixText: suffix,
    keyboardType: phone ? TextInputType.phone : keyboard,
    inputFormatters: phone ? [LengthLimitingTextInputFormatter(11)] : null,
    validator: v,
    maxLines: maxLines,
  );

  String? number(String? x, double min, double? max, bool ex, String l) {
    if (x == null || x.isEmpty) return null;
    final n = double.tryParse(x);
    if (n == null) return 'Enter a valid $l.';
    if (ex ? n <= min : n < min) {
      return 'Enter a $l greater than ${min.toInt()}.';
    }
    if (max != null && n > max) {
      return 'Enter a $l from ${min.toInt()} to ${max.toInt()}.';
    }
    return null;
  }

  String? integer(String? x, int min, int max, String l) {
    if (x == null || x.isEmpty) return null;
    final n = int.tryParse(x);
    return n == null
        ? 'Enter $l as a whole number.'
        : n < min || n > max
        ? 'Enter $l from $min to $max.'
        : null;
  }

  /// Like [integer] but the value may not be left empty. Used for the four
  /// custom-range fields: leaving one blank used to pass validation and then
  /// crash on `int.parse` when Continue was pressed.
  String? requiredInteger(String? x, int min, int max, String l) =>
      x == null || x.trim().isEmpty
      ? 'Enter $l.'
      : integer(x.trim(), min, max, l);
}

class _IntroRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _IntroRow({
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

class _ConnectionRow extends StatelessWidget {
  final String label;
  final Widget chip;
  const _ConnectionRow({required this.label, required this.chip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AleraColors.textSecondary,
            ),
          ),
        ),
        chip,
      ],
    );
  }
}

class _CreatedRow extends StatelessWidget {
  final IconData? icon;

  /// A branded SVG (e.g. the devices icons), used instead of [icon] when
  /// set. Takes priority over [icon].
  final String? iconAsset;
  final String title;
  final String? subtitle;
  final Widget trailing;

  const _CreatedRow({
    this.icon,
    this.iconAsset,
    required this.title,
    required this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AleraColors.primarySoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: iconAsset != null
              ? AleraSvgIcon(assetPath: iconAsset!, width: 18, height: 18)
              : Icon(icon, size: 18, color: AleraColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
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
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AleraTypography.body.copyWith(fontSize: 12),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}
