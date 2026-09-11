import 'dart:async';
import 'dart:convert';
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
import 'patient_access_setup_page.dart';

enum _Step { intro, personal, care, monitoring, review, created, pairing, code }

class AddPatientPage extends StatefulWidget {
  final CaregiverPatientDataSource dataSource;
  final Future<PatientDetailDto> Function(String patientId)? loadPatientDetail;
  final String? householdCode;
  final FutureOr<void> Function(PatientCreatedResponse) onPatientCreated;
  const AddPatientPage({
    super.key,
    required this.dataSource,
    this.loadPatientDetail,
    required this.householdCode,
    required this.onPatientCreated,
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
  DateTime? birthdate;
  String? sex, error;
  bool custom = false,
      busy = false,
      issuing = false,
      called = false,
      settingsFailed = false;
  PatientCreatedResponse? created;
  PatientAccessCodeResponse? issued;
  Timer? _pollTimer;
  bool _polling = false;
  bool _accessConnected = false;
  bool _accessExpired = false;
  bool _foreground = true;

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
    if (x == null)
      Navigator.pop(context);
    else
      go(x);
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
  Future<void> create() async {
    if (busy || created != null) return;
    setState(() => busy = true);
    try {
      created = await widget.dataSource.createPatient(request);
      if (!called) {
        called = true;
        await widget.onPatientCreated(created!);
      }
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
      if (mounted) setState(() => step = _Step.created);
    } catch (e) {
      if (mounted)
        setState(
          () =>
              error = msg(e, 'Unable to create the patient. Please try again.'),
        );
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
      if (mounted) setState(() => settingsFailed = false);
    } catch (e) {
      if (mounted)
        setState(() => error = msg(e, 'Custom settings were not saved.'));
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
      if (mounted)
        setState(() => error = msg(e, 'Unable to issue an access code.'));
    } finally {
      if (mounted) setState(() => issuing = false);
    }
  }

  Future<void> finish() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        title: const Text('Finish setup for now?'),
        content: const Text(
          'The patient remains saved but cannot send readings until connected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(x),
            child: const Text('Continue setup'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(x, true),
            child: const Text('Finish for now'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  Future<void> confirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (x) => AlertDialog(
        title: Text('Create ${name.text.trim()}’s profile?'),
        content: const Text(
          'The patient will be added using the reviewed information and connection can happen afterward.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(x),
            child: const Text('Review again'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(x, true),
            child: const Text('Create patient'),
          ),
        ],
      ),
    );
    if (ok == true) await create();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: step == _Step.intro,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) back();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Add Patient'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
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
  Widget list(List<Widget> x) =>
      ListView(padding: const EdgeInsets.all(AleraSpacing.medium), children: x);
  Widget intro() => list([
    Text('Add someone to your care', style: AleraTypography.pageTitle),
    const SizedBox(height: 12),
    Text(
      'Create a profile, configure monitoring, and optionally connect patient access.',
      style: AleraTypography.body,
    ),
    const SizedBox(height: 24),
    AleraButton(label: 'Start setup', onPressed: () => go(_Step.personal)),
  ]);
  Widget personal() => Form(
    key: p,
    child: list([
      Text('Personal Information', style: AleraTypography.pageTitle),
      field(
        name,
        'Full name *',
        key: const Key('patient-name-field'),
        v: (x) => x == null || x.trim().isEmpty
            ? 'Enter the patient’s full name.'
            : x.trim().length > 150
            ? 'Use 150 characters or fewer.'
            : null,
      ),
      field(
        phone,
        'Phone number',
        phone: true,
        v: (x) => (x?.length ?? 0) > 11 ? 'Use 11 characters or fewer.' : null,
      ),
      field(address, 'Address or room'),
      ListTile(
        key: const Key('birthdate-field'),
        title: Text(birthdate == null ? 'Birthdate' : date(birthdate!)),
        onTap: pick,
      ),
      DropdownButtonFormField<String>(
        key: const Key('sex-field'),
        value: sex,
        items: const [
          DropdownMenuItem(value: 'MALE', child: Text('Male')),
          DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
          DropdownMenuItem(value: 'OTHER', child: Text('Other')),
        ],
        onChanged: (x) => setState(() => sex = x),
      ),
      buttons(() => back(), () {
        if (p.currentState!.validate()) go(returnTo ?? _Step.care);
      }),
    ]),
  );
  Widget care() => Form(
    key: c,
    child: list([
      Text('Care Information', style: AleraTypography.pageTitle),
      const Text(
        'Baseline readings are reference values and do not control alert thresholds.',
      ),
      field(
        emergencyName,
        'Emergency contact name',
        v: (x) =>
            (x?.length ?? 0) > 150 ? 'Use 150 characters or fewer.' : null,
      ),
      field(
        emergencyPhone,
        'Emergency contact phone',
        v: (x) => (x?.length ?? 0) > 30 ? 'Use 30 characters or fewer.' : null,
      ),
      field(conditions, 'Known conditions'),
      field(medications, 'Medications'),
      field(
        hr,
        'Baseline heart rate',
        key: const Key('heart-rate-field'),
        v: (x) => number(x, 0, null, true, 'heart rate'),
      ),
      field(
        spo2,
        'Baseline SpO₂',
        key: const Key('spo2-field'),
        v: (x) => number(x, 0, 100, false, 'SpO₂'),
      ),
      field(notes, 'Monitoring notes'),
      buttons(
        back,
        () {
          if (c.currentState!.validate()) go(returnTo ?? _Step.monitoring);
        },
        skip: () {
          if (c.currentState!.validate()) go(returnTo ?? _Step.monitoring);
        },
      ),
    ]),
  );
  Widget monitoring() => Form(
    key: m,
    child: list([
      Text('Monitoring Settings', style: AleraTypography.pageTitle),
      RadioListTile<bool>(
        key: const Key('default-monitoring-option'),
        value: false,
        groupValue: custom,
        onChanged: (x) => setState(() => custom = x!),
        title: const Text('Alera defaults: HR 60–100, minimum SpO₂ 95'),
      ),
      RadioListTile<bool>(
        key: const Key('custom-monitoring-option'),
        value: true,
        groupValue: custom,
        onChanged: (x) => setState(() => custom = x!),
        title: const Text('Custom monitoring ranges'),
      ),
      if (custom) ...[
        field(
          hrMin,
          'HR minimum',
          key: const Key('hr-min-field'),
          v: (x) => integer(x, 1, 999, 'HR minimum'),
        ),
        field(
          hrMax,
          'HR maximum',
          key: const Key('hr-max-field'),
          v: (x) => integer(x, 1, 999, 'HR maximum'),
        ),
        field(
          spo2Min,
          'SpO₂ minimum',
          key: const Key('spo2-min-field'),
          v: (x) => integer(x, 0, 100, 'SpO₂ minimum'),
        ),
        field(
          spo2Max,
          'SpO₂ maximum (optional)',
          key: const Key('spo2-max-field'),
          v: (x) => integer(x, 0, 100, 'SpO₂ maximum'),
        ),
        const Text('Alera’s Critical safety overrides still apply.'),
      ],
      buttons(back, () {
        if (m.currentState!.validate() &&
            (!custom ||
                (int.parse(hrMin.text) <= int.parse(hrMax.text) &&
                    (spo2Max.text.isEmpty ||
                        int.parse(spo2Min.text) <= int.parse(spo2Max.text)))))
          go(returnTo ?? _Step.review);
      }),
    ]),
  );
  Widget review() => list([
    Text('Review', style: AleraTypography.pageTitle),
    summary('Personal', name.text, () => edit(_Step.personal)),
    summary(
      'Care',
      conditions.text.isEmpty ? 'No care information' : conditions.text,
      () => edit(_Step.care),
    ),
    summary(
      'Monitoring',
      custom ? 'Custom' : 'Alera defaults',
      () => edit(_Step.monitoring),
    ),
    const AleraSectionCard(
      title: 'Connection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patient access: Not connected'),
          Text('Smartwatch: Not connected'),
        ],
      ),
    ),
    if (error != null) err,
    AleraButton(
      label: busy ? 'Creating…' : 'Create patient',
      onPressed: busy ? null : confirm,
    ),
  ]);
  void edit(_Step x) => setState(() {
    returnTo = _Step.review;
    step = x;
  });
  Widget summary(String a, String b, VoidCallback e) => AleraSectionCard(
    title: a,
    child: Row(
      children: [
        Expanded(child: Text(b)),
        TextButton(onPressed: e, child: const Text('Edit')),
      ],
    ),
  );
  Widget createdView() => list([
    Text(
      '${created!.fullName} has been added',
      style: AleraTypography.pageTitle,
    ),
    const Text('Profile: Created'),
    Text('Monitoring: ${custom ? 'Custom' : 'Alera defaults'}'),
    const Text('Patient access: Not connected'),
    const Text('Smartwatch: Not connected'),
    if (settingsFailed) ...[
      err,
      AleraButton(
        label: 'Retry settings',
        onPressed: busy ? null : retrySettings,
      ),
      AleraButton(
        label: 'Use Alera defaults',
        onPressed: () => setState(() => settingsFailed = false),
      ),
    ],
    AleraButton(
      label: 'Connect patient access',
      onPressed: widget.loadPatientDetail == null
          ? () => go(_Step.pairing)
          : openPatientAccess,
    ),
    AleraButton(
      label: 'Finish for now',
      variant: AleraButtonVariant.secondary,
      onPressed: finish,
    ),
  ]);
  Widget pairing() => list([
    Text('Connect patient access', style: AleraTypography.pageTitle),
    const Text(
      'Generate a one-time code for the patient to scan or enter. The code expires after 24 hours.',
    ),
    if (error != null) err,
    AleraButton(
      label: issuing ? 'Generating…' : 'Generate access code',
      onPressed: issuing ? null : issue,
    ),
    AleraButton(
      label: 'Do this later',
      variant: AleraButtonVariant.secondary,
      onPressed: finish,
    ),
  ]);
  Widget code() => list([
    Text('Patient access', style: AleraTypography.pageTitle),
    if (_accessConnected) ...[
      Text('${created!.fullName}’s patient access is connected'),
      AleraButton(
        label: 'Done',
        variant: AleraButtonVariant.secondary,
        onPressed: () => Navigator.pop(context),
      ),
    ] else if (_accessExpired) ...[
      const Text('The invitation expired.'),
      AleraButton(
        label: 'Done',
        variant: AleraButtonVariant.secondary,
        onPressed: () => Navigator.pop(context),
      ),
    ] else ...[
      const Text('Valid for 24 hours and usable only once.'),
      SelectableText(
        issued!.accessCode,
        key: const Key('issued-access-code'),
        style: AleraTypography.pageTitle,
      ),
      Text('Expires ${dateTime(issued!.expiresAt)}'),
      QrImageView(
        key: const Key('access-code-qr'),
        data: buildPatientAccessQrPayload(accessCode: issued!.accessCode),
        size: 220,
      ),
      AleraButton(
        label: 'Copy',
        onPressed: () =>
            Clipboard.setData(ClipboardData(text: issued!.accessCode)),
      ),
      AleraButton(
        label: 'Share',
        onPressed: () => SharePlus.instance.share(
          ShareParams(
            text:
                '${created!.fullName}\nAccess code: ${issued!.accessCode}\nExpires ${dateTime(issued!.expiresAt)}',
          ),
        ),
      ),
      AleraButton(
        label: 'Done',
        variant: AleraButtonVariant.secondary,
        onPressed: () => Navigator.pop(context),
      ),
    ],
  ]);
  Widget buttons(VoidCallback b, VoidCallback n, {VoidCallback? skip}) =>
      Column(
        children: [
          if (error != null) err,
          Row(
            children: [
              Expanded(
                child: AleraButton(
                  label: 'Back',
                  variant: AleraButtonVariant.secondary,
                  onPressed: b,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AleraButton(label: 'Continue', onPressed: n),
              ),
            ],
          ),
          if (skip != null)
            AleraButton(
              label: 'Skip for now',
              variant: AleraButtonVariant.secondary,
              onPressed: skip,
            ),
        ],
      );
  Widget field(
    TextEditingController x,
    String label, {
    Key? key,
    bool phone = false,
    String? Function(String?)? v,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextFormField(
      key: key,
      controller: x,
      keyboardType: phone ? TextInputType.phone : null,
      inputFormatters: phone ? [LengthLimitingTextInputFormatter(11)] : null,
      validator: v,
      decoration: InputDecoration(labelText: label),
    ),
  );
  Widget get err => Text(
    error!,
    key: const Key('patient-error'),
    style: const TextStyle(color: AleraColors.critical),
  );
  Future<void> pick() async {
    final now = DateTime.now();
    final x = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: birthdate ?? DateTime(now.year - 65),
    );
    if (x != null && mounted) setState(() => birthdate = x);
  }

  String? number(String? x, double min, double? max, bool ex, String l) {
    if (x == null || x.isEmpty) return null;
    final n = double.tryParse(x);
    if (n == null) return 'Enter a valid $l.';
    if (ex ? n <= min : n < min)
      return 'Enter a $l greater than ${min.toInt()}.';
    if (max != null && n > max)
      return 'Enter a $l from ${min.toInt()} to ${max.toInt()}.';
    return null;
  }

  String? integer(String? x, int min, int max, String l) {
    if (x == null || x.isEmpty) return null;
    final n = int.tryParse(x);
    return n == null
        ? 'Enter an integer $l.'
        : n < min || n > max
        ? 'Enter a $l from $min to $max.'
        : null;
  }
}

String date(DateTime x) =>
    '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
String dateTime(DateTime x) =>
    '${date(x.toLocal())} ${x.toLocal().hour.toString().padLeft(2, '0')}:${x.toLocal().minute.toString().padLeft(2, '0')}';
String buildPatientAccessQrPayload({required String accessCode}) => jsonEncode({
  'type': 'alera_patient_access',
  'version': 2,
  'access_code': accessCode,
});
