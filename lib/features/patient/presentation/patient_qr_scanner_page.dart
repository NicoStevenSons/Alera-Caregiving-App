import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../design_system/alera_colors.dart';
import '../../../design_system/alera_typography.dart';
import '../../../design_system/widgets/alera_button.dart';
import '../../caregiver/data/auth/caregiver_session_controller.dart';
import '../data/auth/patient_auth_api.dart';
import 'patient_access.dart';

class PatientQrScannerPage extends StatefulWidget {
  final CaregiverSessionController sessionController;

  const PatientQrScannerPage({
    super.key,
    required this.sessionController,
  });

  @override
  State<PatientQrScannerPage> createState() => _PatientQrScannerPageState();
}

class _PatientQrScannerPageState extends State<PatientQrScannerPage> {
  final MobileScannerController _scanner = MobileScannerController(
    autoStart: true,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  final PatientQrDetectionBoundary _detections = PatientQrDetectionBoundary();

  bool _connecting = false;
  bool _disposed = false;
  String? _error;

  @override
  void dispose() {
    _disposed = true;
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _stopScanner() async {
    if (_disposed) return;

    try {
      await _scanner.stop();
    } on MobileScannerException {
      // Scanner may already be stopped during a lifecycle change.
    }
  }

  Future<void> _startScanner() async {
    if (_disposed || _connecting || !mounted) return;

    try {
      await _scanner.start(cameraDirection: CameraFacing.back);
    } on MobileScannerException {
      if (mounted && !_disposed) {
        setState(
          () => _error =
              'Camera access is needed to scan your patient QR code.',
        );
      }
    }
  }

  Future<void> _detect(BarcodeCapture capture) async {
    if (_connecting || capture.barcodes.isEmpty) return;

    final result = _detections.inspect(
      capture.barcodes.map((barcode) => barcode.rawValue),
    );

    if (result == null) return;

    if (result is InvalidPatientQr) {
      if (mounted) setState(() => _error = result.message);
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
    });

    await _stopScanner();

    if (!mounted || _disposed) return;

    try {
      await widget.sessionController.accessPatient(
        accessCode: (result as ValidPatientQr).accessCode,
      );
    } on PatientAccessFailure catch (failure) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _error = failure.message;
          _detections.allowRetry();
        });
        await _startScanner();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _error =
              'We couldn’t connect to Alera. Check your internet connection and try again.';
          _detections.allowRetry();
        });
        await _startScanner();
      }
    }
  }

  Widget _backButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          onPressed: _connecting ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, size: 28),
          color: const Color(0xFFB4AEC2),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.expand(),
          visualDensity: VisualDensity.compact,
          splashRadius: 20,
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _backButton(),
              const SizedBox(height: 16), // Reduced from 48 to 16
              Text(
                'Scan your patient QR code',
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
                  'Position the QR code inside the frame to securely access your Alera account.',
                  textAlign: TextAlign.center,
                  style: AleraTypography.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 20), // Reduced from 28 to 20
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        key: const Key('patient-qr-scanner'),
                        controller: _scanner,
                        useAppLifecycleState: true,
                        onDetect: _detect,
                        errorBuilder: (context, error) => const ColoredBox(
                          color: Colors.black87,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Camera access is needed to scan your patient QR code.',
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const IgnorePointer(child: _ScannerFrameOverlay()),
                    ],
                  ),
                ),
              ),
              if (_connecting) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                Text(
                  'Connecting to your household...',
                  textAlign: TextAlign.center,
                  style: AleraTypography.label.copyWith(fontSize: 11),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('scanner-error'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AleraColors.critical,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Flashlight',
                    onPressed: _connecting ? null : _scanner.toggleTorch,
                    icon: const Icon(Icons.flashlight_on),
                    color: AleraColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AleraButton(
                      label: 'Enter code manually',
                      variant: AleraButtonVariant.secondary,
                      height: 40,
                      onPressed: _connecting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerFrameOverlay extends StatelessWidget {
  const _ScannerFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.72,
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            key: const Key('patient-qr-scan-frame'),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}