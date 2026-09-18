import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../design_system/alera_spacing.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_button.dart';
import '../../data/api/caregiver_patient_api_data_source.dart';
import '../../data/api/dto/patient_dto.dart';

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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace invitation?'),
          content: const Text('The previous unused code will stop working.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace invitation'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _issuing = true);
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Patient access')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AleraSpacing.medium),
        children: [
          Text('Connect patient access', style: AleraTypography.pageTitle),
          if (_connected) ...[
            Text('${widget.patientName}’s Alera access is connected'),
          ] else if (_expired) ...[
            const Text('The invitation expired.'),
            AleraButton(
              label: _issuing ? 'Generating…' : 'Generate access code',
              onPressed: _issuing ? null : () => _issue(replacing: false),
            ),
          ] else if (_issued != null) ...[
            const Text('Valid for 24 hours and usable only once.'),
            SelectableText(
              _issued!.accessCode,
              key: const Key('issued-access-code'),
              style: AleraTypography.pageTitle,
            ),
            Text('Expires ${_format(_issued!.expiresAt)}'),
            QrImageView(
              key: const Key('access-code-qr'),
              data: buildPatientAccessQrPayload(
                accessCode: _issued!.accessCode,
              ),
              size: 220,
            ),
            AleraButton(
              label: 'Copy',
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: _issued!.accessCode)),
            ),
            AleraButton(
              label: 'Share',
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      '${widget.patientName}\nAccess code: ${_issued!.accessCode}',
                ),
              ),
            ),
          ] else if (_status.status == PatientAccessState.invitePending) ...[
            const Text('Invitation pending'),
            if (_status.pendingExpiresAt != null)
              Text('Invitation expires ${_format(_status.pendingExpiresAt!)}'),
            AleraButton(
              label: _issuing ? 'Replacing…' : 'Replace invitation',
              onPressed: _issuing ? null : () => _issue(replacing: true),
            ),
          ] else ...[
            const Text(
              'Generate a one-time code for the patient to scan or enter.',
            ),
            if (_status.status == PatientAccessState.notConnected)
              AleraButton(
                label: _issuing ? 'Generating…' : 'Generate access code',
                onPressed: _issuing ? null : () => _issue(replacing: false),
              )
            else
              const Text('Patient access status is unavailable.'),
          ],
          AleraButton(
            label: 'Done',
            variant: AleraButtonVariant.secondary,
            onPressed: _done,
          ),
        ],
      ),
    ),
  );
}

String _format(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String buildPatientAccessQrPayload({required String accessCode}) => jsonEncode({
  'type': 'alera_patient_access',
  'version': 2,
  'access_code': accessCode,
});
