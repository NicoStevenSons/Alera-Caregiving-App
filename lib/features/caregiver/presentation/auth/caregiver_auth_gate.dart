import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_theme.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../../../design_system/widgets/alera_card.dart';
import '../../../../interfaces/elderly_interface.dart';
import '../../../patient/data/auth/patient_auth_api.dart';
import '../../../patient/presentation/patient_access.dart';
import '../../../patient/presentation/patient_qr_scanner_page.dart';
import '../../caregiver_shell.dart';
import '../../data/api/caregiver_alert_api_data_source.dart';
import '../../data/api/caregiver_patient_api_data_source.dart';
import '../../data/auth/caregiver_auth_api.dart';
import '../../data/auth/caregiver_session_controller.dart';
import '../../data/auth/caregiver_token_store.dart';
import '../../domain/repositories/caregiver_repository.dart';


class HouseholdCodeInput extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;
  final String? Function(String?) validator;

  const HouseholdCodeInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
    required this.validator,
  });

  @override
  State<HouseholdCodeInput> createState() => _HouseholdCodeInputState();
}

class _HouseholdCodeInputState extends State<HouseholdCodeInput> {
  final _fieldController = TextEditingController();
  final _focusNode = FocusNode();

  String get _rawCode => _fieldController.text.toUpperCase();

  @override
  void initState() {
    super.initState();
    _syncFromParent();
    widget.controller.addListener(_syncFromParent);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromParent);
    _fieldController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncFromParent() {
    final raw = widget.controller.text
        .replaceAll('-', '')
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();

    if (_fieldController.text != raw) {
      _fieldController.value = TextEditingValue(
        text: raw,
        selection: TextSelection.collapsed(offset: raw.length),
      );
    }
  }

  String _formatted(String raw) {
    final leftLength = raw.length < 4 ? raw.length : 4;
    final left = raw.substring(0, leftLength);
    final right = raw.length > 4 ? raw.substring(4) : '';
    return right.isEmpty ? left : '$left-$right';
  }

  void _onChanged(String value, FormFieldState<String> field) {
    final raw = value
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();

    _fieldController.value = TextEditingValue(
      text: raw,
      selection: TextSelection.collapsed(offset: raw.length),
    );

    final formatted = _formatted(raw);
    widget.controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    field.didChange(formatted);

    if (raw.length == 8) {
      widget.onSubmitted(formatted);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      builder: (field) {
        return GestureDetector(
          onTap: widget.enabled ? _focusNode.requestFocus : null,
          child: Column(
            children: [
              SizedBox(
                width: 1,
                height: 1,
                child: TextField(
                  controller: _fieldController,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  onChanged: (value) => _onChanged(value, field),
                  onSubmitted: (_) => widget.onSubmitted(widget.controller.text),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(4, _buildDigit),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...List.generate(4, (index) => _buildDigit(index + 4)),
                ],
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    field.errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AleraColors.critical,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDigit(int index) {
    final value = index < _rawCode.length ? _rawCode[index] : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 30,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0FF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          value,
          style: AleraTypography.sectionTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class CaregiverAuthGate extends StatefulWidget {
  final CaregiverRepository repository;
  final CaregiverSessionController? sessionController;

  const CaregiverAuthGate({
    super.key,
    required this.repository,
    this.sessionController,
  });

  @override
  State<CaregiverAuthGate> createState() => _CaregiverAuthGateState();
}

class _CaregiverAuthGateState extends State<CaregiverAuthGate> {
  late final CaregiverSessionController _session;
  GlobalKey<NavigatorState> _navigationKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _session = widget.sessionController ?? CaregiverSessionController.instance;
    _session.addListener(_onSessionChanged);
    _session.restoreSession();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() => _navigationKey = GlobalKey<NavigatorState>());
    }
  }

  Future<void> _signOut() async {
    try {
      await _session.logout();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            action: SnackBarAction(label: 'Retry', onPressed: _signOut),
            content: const Text(
              'Unable to clear saved sign-in. Please try signing out again.',
            ),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final Widget page = switch (_session.status) {
      CaregiverSessionStatus.restoring => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      CaregiverSessionStatus.unauthenticated => Theme(
        data: AleraTheme.caregiver(Theme.of(context)),
        child: HouseholdAuthFlow(sessionController: _session),
      ),
      CaregiverSessionStatus.authenticated =>
        _session.sessionType == SessionType.elderlyPatient
            ? ElderlyInterface(onSignOut: _signOut)
            : CaregiverShell(
                repository: widget.repository,
                alertDataSource: CaregiverAlertApiDataSource(session: _session),
                loadNotificationAlert: CaregiverAlertApiDataSource(
                  session: _session,
                ).fetchAlert,
                patientDataSource: CaregiverPatientApiDataSource(
                  session: _session,
                ),
                householdCode: _session.householdCode,
                onSignOut: _signOut,
              ),
    };

    return NavigatorPopHandler<void>(
      onPopWithResult: (_) => _navigationKey.currentState?.maybePop(),
      child: Navigator(
        key: _navigationKey,
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => page),
      ),
    );
  }
}

enum _AuthStep {
  welcome,
  role,
  household,
  caregiver,
  patientOptions,
  patientManual,
}

enum _RoleSelection {
  caregiver,
  patient,
}

class HouseholdAuthFlow extends StatefulWidget {
  final CaregiverSessionController sessionController;

  const HouseholdAuthFlow({super.key, required this.sessionController});

  @override
  State<HouseholdAuthFlow> createState() => _HouseholdAuthFlowState();
}

class _HouseholdAuthFlowState extends State<HouseholdAuthFlow> {
  final _formKey = GlobalKey<FormState>();
  final _household = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _accessCode = TextEditingController();

  _AuthStep _step = _AuthStep.welcome;
  _RoleSelection? _selectedRole;
  bool _submitting = false;
  bool _goingBack = false;
  bool _obscurePassword = true;
  String? _error;
  String? _householdName;

  @override
  void dispose() {
    _household.dispose();
    _email.dispose();
    _password.dispose();
    _accessCode.dispose();
    super.dispose();
  }

  void _go(_AuthStep step) {
    if (_submitting) return;

    setState(() {
      _goingBack = _stepIndex(step) < _stepIndex(_step);
      _step = step;
      if (step == _AuthStep.household) _householdName = null;
      _error = null;
      _password.clear();
      _accessCode.clear();
    });
  }

  int _stepIndex(_AuthStep step) => switch (step) {
        _AuthStep.welcome => 0,
        _AuthStep.role => 1,
        _AuthStep.household || _AuthStep.patientOptions => 2,
        _AuthStep.caregiver || _AuthStep.patientManual => 3,
      };

  void _continueRole() {
    final selectedRole = _selectedRole;
    if (_submitting || selectedRole == null) return;

    if (selectedRole == _RoleSelection.caregiver) {
      _go(_AuthStep.household);
    } else {
      _go(_AuthStep.patientOptions);
    }
  }

  void _back() => _go(switch (_step) {
        _AuthStep.welcome => _AuthStep.welcome,
        _AuthStep.role => _AuthStep.welcome,
        _AuthStep.household => _AuthStep.role,
        _AuthStep.caregiver => _AuthStep.household,
        _AuthStep.patientOptions => _AuthStep.role,
        _AuthStep.patientManual => _AuthStep.patientOptions,
      });

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _continueHousehold() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    _household.text = _household.text.trim().toUpperCase();

    setState(() {
      _submitting = true;
      _error = null;
      _householdName = null;
    });

    try {
      final validation = await widget.sessionController.validateHousehold(
        _household.text,
      );
      if (!mounted) return;
      setState(() {
        _householdName = validation.householdName;
        _step = _AuthStep.caregiver;
      });
    } on HouseholdValidationException catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We couldn’t verify the household right now. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (_step == _AuthStep.patientManual) {
        await widget.sessionController.accessPatient(
          accessCode: normalizePatientAccessCode(_accessCode.text),
        );
      } else {
        await widget.sessionController.login(
          householdCode: _household.text,
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on CaregiverLoginFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on PatientAccessFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to sign in. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildWelcome() {
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
                    child: SizedBox(
                      width: 216,
                      child: AleraButton(
                        label: 'Get Started',
                        variant: AleraButtonVariant.pill,
                        onPressed: () => _go(_AuthStep.role),
                      ),
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


  Widget _roleCard({
    required _RoleSelection role,
    required String title,
    required String description,
    required String asset,
  }) {
    final selected = _selectedRole == role;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submitting
              ? null
              : () => setState(() => _selectedRole = role),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFE4D9FB)
                  : const Color(0xFFF6F1FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 72,
                  child: SvgPicture.asset(
                    asset,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AleraTypography.sectionTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AleraTypography.label.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _authAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: _submitting ? null : _back,
        icon: const Icon(Icons.chevron_left, size: 28),
        color: const Color(0xFFB4AEC2),
      ),
    );
  }

  Widget _buildPatientOptions() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 162),
                Text(
                  'Connect to your care household',
                  textAlign: TextAlign.center,
                  style: AleraTypography.pageTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Scan the QR code provided by your caregiver\nto securely access your Alera account.',
                    textAlign: TextAlign.center,
                    style: AleraTypography.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 56),
                Center(
                  child: SizedBox(
                    width: 216,
                    child: AleraButton(
                      label: 'Scan QR Code',
                      variant: AleraButtonVariant.pill,
                      height: 40,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PatientQrScannerPage(
                            sessionController: widget.sessionController,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'or',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFB4AEC2)),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 216,
                    child: AleraButton(
                      label: 'Enter code manually',
                      variant: AleraButtonVariant.lightPill,
                      height: 40,
                      onPressed: _submitting
                          ? null
                          : () => _go(_AuthStep.patientManual),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your patient code can only be used once.',
                  textAlign: TextAlign.center,
                  style: AleraTypography.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientManual() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 190,
                    child: SvgPicture.asset(
                      'alera-figma-assets/assets/icons/onboarding/patient-code.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter your patient code',
                    textAlign: TextAlign.center,
                    style: AleraTypography.pageTitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    key: const Key('patient-access-code-field'),
                    controller: _accessCode,
                    enabled: !_submitting,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    inputFormatters: const [PatientAccessCodeFormatter()],
                    validator: (value) => isValidPatientAccessCode(
                      normalizePatientAccessCode(value ?? ''),
                    )
                        ? null
                        : 'Enter a valid patient code.',
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'XXXX - XXXX - XXXX',
                      hintStyle: const TextStyle(color: Color(0xFFB5A6DB)),
                      filled: true,
                      fillColor: const Color(0xFFF7F3FF),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0D6F5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AleraColors.primary,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AleraColors.critical),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AleraColors.critical,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      key: const Key('auth-error'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AleraColors.critical,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'Don’t have a code? Contact your care administrator.',
                    textAlign: TextAlign.center,
                    style: AleraTypography.label.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
          child: AleraButton(
            label: _submitting ? 'Connecting…' : 'Continue',
            variant: AleraButtonVariant.pill,
            onPressed: _submitting ? null : _submit,
            height: 40,
          ),
        ),
      ],
    );
  }

  Widget _authTextField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AleraTypography.label.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: key,
          controller: controller,
          enabled: !_submitting,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: !obscureText,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFFB5A6DB)),
            filled: true,
            fillColor: const Color(0xFFF7F3FF),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0D6F5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AleraColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AleraColors.critical),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AleraColors.critical,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _householdSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 58,
          height: 58,
          child: SvgPicture.asset(
            'alera-figma-assets/assets/icons/onboarding/household-icon.svg',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Household code:',
              style: AleraTypography.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _household.text,
              key: const Key('selected-household'),
              style: AleraTypography.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: _submitting ? null : () => _go(_AuthStep.household),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFEDE7F8),
            foregroundColor: AleraColors.textSecondary,
            minimumSize: const Size(46, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Edit'),
        ),
      ],
    );
  }

  Widget _buildCaregiverSignIn() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 10, 32, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 54),
                  Text(
                    'Sign in to ${_householdName ?? 'your'} household',
                    textAlign: TextAlign.center,
                    style: AleraTypography.pageTitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _householdSummary(),
                  const SizedBox(height: 42),
                  _authTextField(
                    key: const Key('caregiver-email-field'),
                    controller: _email,
                    label: 'Email',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: _required,
                  ),
                  const SizedBox(height: 18),
                  _authTextField(
                    key: const Key('caregiver-password-field'),
                    controller: _password,
                    label: 'Password',
                    hintText: 'Enter your password',
                    obscureText: _obscurePassword,
                    validator: _required,
                    onFieldSubmitted: (_) => _submit(),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: _submitting
                          ? null
                          : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFFA684E8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Your account is created by your care administrator.',
                    textAlign: TextAlign.center,
                    style: AleraTypography.label.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      key: const Key('auth-error'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AleraColors.critical,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
          child: AleraButton(
            label: _submitting ? 'Signing in…' : 'Sign in',
            onPressed: _submitting ? null : _submit,
            variant: AleraButtonVariant.pill,
            height: 40,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _AuthStep.welcome) {
      return PopScope(
        canPop: true,
        child: _buildWelcome(),
      );
    }

    final title = switch (_step) {
      _AuthStep.welcome => 'Welcome to Alera',
      _AuthStep.role => 'How will you use Alera?',
      _AuthStep.household => 'Enter household code',
      _AuthStep.caregiver => 'Caregiver sign in',
      _AuthStep.patientOptions => 'Connect to your care household',
      _AuthStep.patientManual => 'Enter your patient code',
    };

    final isRoleStep = _step == _AuthStep.role;

    return PopScope(
      canPop: _step == _AuthStep.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: _authAppBar(),
        body: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            ),
            transitionBuilder: (child, animation) {
              final isIncoming = child.key == ValueKey<_AuthStep>(_step);
              final incomingOffset = _goingBack
                  ? const Offset(-1, 0)
                  : const Offset(1, 0);
              final outgoingOffset = Offset(-incomingOffset.dx, 0);
              final curve = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              );

              return ClipRect(
                child: SlideTransition(
                  position: isIncoming
                      ? Tween<Offset>(
                          begin: incomingOffset,
                          end: Offset.zero,
                        ).animate(curve)
                      : Tween<Offset>(
                          begin: Offset.zero,
                          end: outgoingOffset,
                        ).animate(ReverseAnimation(curve)),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<_AuthStep>(_step),
              child: isRoleStep
              ? Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 18),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AleraTypography.sectionTitle.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 30),
                            _roleCard(
                              role: _RoleSelection.caregiver,
                              title: 'I’m a Caregiver',
                              description:
                                  'Monitor and support the\npeople assigned to your care.',
                              asset:
                                  'alera-figma-assets/assets/icons/onboarding/caregiver-role.svg',
                            ),
                            const SizedBox(height: 20),
                            _roleCard(
                              role: _RoleSelection.patient,
                              title: 'I’m a Patient',
                              description:
                                  'View your personal health\nand connection status.',
                              asset:
                                  'alera-figma-assets/assets/icons/onboarding/patient-role.svg',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                      child: AleraButton(
                        label: 'Continue',
                        onPressed: _selectedRole == null
                            ? null
                            : _continueRole,
                        variant: AleraButtonVariant.pill,
                        height: 40,
                      ),
                    ),
                  ],
                )
                  : _step == _AuthStep.household
                  ? Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                            child: Column(
                              children: [
                                const SizedBox(height: 34),
                                SizedBox(
                                  height: 190,
                                  child: SvgPicture.asset(
                                    'alera-figma-assets/assets/icons/onboarding/household-icon.svg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Enter your Household code',
                                  textAlign: TextAlign.center,
                                  style: AleraTypography.pageTitle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Form(
                                  key: _formKey,
                                  child: HouseholdCodeInput(
                                    controller: _household,
                                    enabled: !_submitting,
                                    onSubmitted: (_) => _continueHousehold(),
                                    validator: (value) => RegExp(
                                      r'^[A-Za-z0-9]{4}-[A-Za-z0-9]{4}$',
                                    ).hasMatch(value?.trim() ?? '')
                                        ? null
                                        : 'Enter a household code in XXXX-XXXX format.',
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    key: const Key('auth-error'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AleraColors.critical,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                Text(
                                  'Don’t have a code? Contact your care administrator.',
                                  textAlign: TextAlign.center,
                                  style: AleraTypography.label.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                          child: AleraButton(
                            label: _submitting ? 'Validating…' : 'Continue',
                            variant: AleraButtonVariant.pill,
                            onPressed:
                                _submitting ? null : _continueHousehold,
                            height: 40,
                          ),
                        ),
                      ],
                    )
                  : _step == _AuthStep.patientOptions
                      ? _buildPatientOptions()
                  : _step == _AuthStep.patientManual
                      ? _buildPatientManual()
                  : _step == _AuthStep.caregiver
                      ? _buildCaregiverSignIn()
                  : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: AleraCard(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(title, style: AleraTypography.pageTitle),
                              const SizedBox(height: 20),

                              if (_step == _AuthStep.caregiver) ...[
                                Text(
                                  'Signing in to ${_householdName!}',
                                  key: const Key('selected-household'),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: _submitting
                                        ? null
                                        : () => _go(_AuthStep.household),
                                    child: const Text('Edit household'),
                                  ),
                                ),
                              ],
                              if (_step == _AuthStep.caregiver) ...[
                                TextFormField(
                                  key: const Key('caregiver-email-field'),
                                  controller: _email,
                                  enabled: !_submitting,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                  validator: _required,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  key: const Key('caregiver-password-field'),
                                  controller: _password,
                                  enabled: !_submitting,
                                  obscureText: true,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                  ),
                                  validator: _required,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  key: const Key('auth-error'),
                                  style: const TextStyle(
                                    color: AleraColors.critical,
                                  ),
                                ),
                              ],
                              if (_step == _AuthStep.caregiver) ...[
                                const SizedBox(height: 20),
                                AleraButton(
                                  label:
                                      _submitting ? 'Signing in…' : 'Sign in',
                                  onPressed: _submitting ? null : _submit,
                                  height: 48,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ),
          ),
        ),
      ),
    );
  }
}
