import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../../../design_system/widgets/alera_confirmation_dialog.dart';
import '../../data/api/caregiver_patient_api_data_source.dart';
import '../../data/api/dto/patient_dto.dart';
import 'widgets/patient_access_views.dart';

export 'widgets/patient_access_views.dart' show buildPatientAccessQrPayload;

enum PatientAccessSetupResult { unchanged, changed }

/// Reusable caregiver flow for a patient's app-access invitation.
class PatientAccessSetupPage extends StatefulWidget {
  final String patientId;
  final String patientName;
  final PatientAccessStatus patientAccess;
  final CaregiverPatientDataSource dataSource;
  final Future<PatientDetailDto> Function(String patientId) loadPatientDetail;

  const PatientAccessSetupPage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientAccess,
    required this.dataSource,
    required this.loadPatientDetail,
  });

  @override
  State<PatientAccessSetupPage> createState() => _PatientAccessSetupPageState();
}

class _PatientAccessSetupPageState extends State<PatientAccessSetupPage>
    with WidgetsBindingObserver {
  PatientAccessCodeResponse? _issued;
  late PatientAccessStatus _status;
  Timer? _timer;
  bool _polling = false;
  bool _issuing = false;
  bool _foreground = true;
  bool _expired = false;
  bool _connected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.patientAccess;
    _expired = _pendingExpired;
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  bool get _pendingExpired =>
      _status.pendingExpiresAt != null &&
      !DateTime.now().toUtc().isBefore(_status.pendingExpiresAt!);
  bool get _shouldPoll =>
      _foreground &&
      !_connected &&
      !_expired &&
      (_issued != null || _status.status == PatientAccessState.invitePending);

  void _startPolling() {
    if (_pendingExpired) {
      _expire();
      return;
    }
    if (!_shouldPoll || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    _poll();
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (_pendingExpired) {
      _expire();
      return;
    }
    if (!_shouldPoll || _polling) return;
    _polling = true;
    try {
      final detail = await widget.loadPatientDetail(widget.patientId);
      if (!mounted) return;
      _status = detail.patientAccessStatus;
      if (_status.status == PatientAccessState.connected) {
        _stopPolling();
        setState(() => _connected = true);
      } else if (_pendingExpired) {
        _expire();
      } else {
        setState(() {});
      }
    } catch (_) {
      // Preserve the invitation; the shared API/session layer handles 401s.
    } finally {
      _polling = false;
    }
  }

  void _expire() {
    _stopPolling();
    if (mounted && !_expired) setState(() => _expired = true);
  }

  Future<void> _issue({required bool replacing}) async {
    if (_issuing || _connected) return;
    if (replacing) {
      final alreadyConnected = _status.status == PatientAccessState.connected;
      final confirmed = await showAleraConfirmationDialog(
        context,
        icon: Icons.autorenew,
        title: alreadyConnected
            ? 'Generate a new login code?'
            : 'Replace invitation?',
        message: alreadyConnected
            ? 'Use this when ${widget.patientName} needs to sign in on a '
                  'new or reset phone. Any older unused code will stop working.'
            : 'The previous unused code will stop working.',
        cancelLabel: 'Cancel',
        confirmLabel: alreadyConnected ? 'Generate code' : 'Replace invitation',
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _issuing = true;
      _error = null;
    });
    try {
      final issued = await widget.dataSource.createAccessCode(widget.patientId);
      if (!mounted) return;
      setState(() {
        _issued = issued;
        _status = PatientAccessStatus(
          status: PatientAccessState.invitePending,
          statusValue: 'INVITE_PENDING',
          pendingAccessCodeId: issued.accessCodeId,
          pendingExpiresAt: issued.expiresAt,
          connectedAt: null,
        );
        _expired = false;
      });
      _startPolling();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is CaregiverPatientApiFailure
              ? e.message
              : 'Unable to issue an access code. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  void _done() => Navigator.pop(
    context,
    _issued != null || _connected || _expired
        ? PatientAccessSetupResult.changed
        : PatientAccessSetupResult.unchanged,
  );

  void _share(PatientAccessCodeResponse issued) => SharePlus.instance.share(
    ShareParams(
      text:
          '${widget.patientName}\nAccess code: ${issued.accessCode}\n'
          'Expires ${formatAccessExpiry(issued.expiresAt)}',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<Widget> content;
    Widget? action;

    if (_connected) {
      content = [
        PatientAccessNoticeContent(
          iconAsset:
              'alera-figma-assets/assets/icons/status/no-active-alerts.svg',
          title: '${widget.patientName}’s Alera access is connected',
          message: 'The patient can now sign in with their Alera account.',
        ),
      ];
    } else if (_status.status == PatientAccessState.connected &&
        _issued == null) {
      // Reachable when this page opens for a patient who is already
      // connected (e.g. from the patient detail page's "Generate login
      // code" action) rather than becoming connected during this session.
      content = [
        PatientAccessNoticeContent(
          iconAsset:
              'alera-figma-assets/assets/icons/status/no-active-alerts.svg',
          title: '${widget.patientName}’s Alera access is connected',
          message:
              'Generate a new one-time code if the patient needs to sign in again.',
        ),
      ];
      action = _primaryAction(
        _issuing ? 'Generating…' : 'Generate new login code',
        _issuing ? null : () => _issue(replacing: true),
      );
    } else if (_expired) {
      content = const [
        PatientAccessNoticeContent(
          icon: Icons.timer_off_outlined,
          title: 'The invitation expired.',
          message: 'Generate a new code so the patient can connect.',
        ),
      ];
      action = _primaryAction(
        _issuing ? 'Generating…' : 'Generate access code',
        _issuing ? null : () => _issue(replacing: false),
      );
    } else if (_issued != null) {
      final issued = _issued!;
      content = [
        PatientAccessCodeContent(
          accessCode: issued.accessCode,
          expiresAt: issued.expiresAt,
          onShare: () => _share(issued),
        ),
      ];
    } else if (_status.status == PatientAccessState.invitePending) {
      content = [
        PatientAccessNoticeContent(
          icon: Icons.schedule_outlined,
          title: 'Invitation pending',
          message: 'Waiting for the patient to use their access code.',
          detail: _status.pendingExpiresAt == null
              ? null
              : 'Invitation expires ${formatAccessExpiry(_status.pendingExpiresAt!)}',
        ),
      ];
      action = _primaryAction(
        _issuing ? 'Replacing…' : 'Replace invitation',
        _issuing ? null : () => _issue(replacing: true),
      );
    } else if (_status.status == PatientAccessState.notConnected) {
      content = const [PatientAccessIntroContent()];
      action = _primaryAction(
        _issuing ? 'Generating…' : 'Generate access code',
        _issuing ? null : () => _issue(replacing: false),
      );
    } else {
      content = const [
        PatientAccessNoticeContent(
          icon: Icons.help_outline,
          title: 'Patient access status is unavailable.',
          message: 'Try again in a moment.',
        ),
      ];
    }

    return Scaffold(
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
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: content,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        key: const Key('patient-access-error'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AleraColors.critical,
                        ),
                      ),
                    ),
                  if (action != null) ...[action, const SizedBox(height: 12)],
                  AleraButton(
                    label: 'Done',
                    variant: action == null
                        ? AleraButtonVariant.pill
                        : AleraButtonVariant.lightPill,
                    height: 44,
                    onPressed: _done,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryAction(String label, VoidCallback? onPressed) => AleraButton(
    label: label,
    variant: AleraButtonVariant.pill,
    height: 44,
    onPressed: onPressed,
  );
}
