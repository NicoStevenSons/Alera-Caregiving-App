import 'package:flutter/foundation.dart';

import '../../../patient/data/auth/patient_auth_api.dart';
import 'caregiver_auth_api.dart';
import 'caregiver_token_store.dart';
import '../../../../services/fcm_notification_service.dart';

enum CaregiverSessionStatus { restoring, unauthenticated, authenticated }

abstract interface class CaregiverSession {
  String? get accessToken;
  String? get householdCode;
  Future<void> clearInvalidSession();
}

// Shared by both roles; retains the existing caregiver API/session integration.
class CaregiverSessionController extends ChangeNotifier
    implements CaregiverSession {
  static final CaregiverSessionController instance = CaregiverSessionController(
    tokenStore: SecureCaregiverTokenStore(),
    authApi: CaregiverAuthApi(),
  );

  final CaregiverTokenStore _tokenStore;
  final CaregiverAuthApi _authApi;
  final PatientAuthApi _patientAuthApi;
  CaregiverSessionStatus _status = CaregiverSessionStatus.restoring;
  StoredSession? _session;
  int _revision = 0;
  Future<void> _storageWork = Future.value();

  factory CaregiverSessionController({
    required CaregiverTokenStore tokenStore,
    required CaregiverAuthApi authApi,
    PatientAuthApi? patientAuthApi,
  }) => CaregiverSessionController._(
    tokenStore,
    authApi,
    patientAuthApi ?? PatientAuthApi(),
  );

  CaregiverSessionController._(
    this._tokenStore,
    this._authApi,
    this._patientAuthApi,
  );

  CaregiverSessionStatus get status => _status;
  SessionType? get sessionType => _session?.type;
  @override
  String? get accessToken => _session?.token;
  @override
  String? get householdCode => _session?.householdCode;

  Future<HouseholdValidationResult> validateHousehold(String householdCode) =>
      _authApi.validateHousehold(householdCode: householdCode);

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _storageWork.then((_) => operation());
    _storageWork = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> restoreSession() async {
    final revision = ++_revision;
    await _serialize(() async {
      StoredSession? stored;
      try {
        stored = await _tokenStore.readSession();
      } catch (_) {
        try {
          await _tokenStore.clearSession();
        } catch (_) {
          /* Fail closed. */
        }
      }
      if (revision != _revision) return;
      _session = stored;
      _status = stored == null
          ? CaregiverSessionStatus.unauthenticated
          : CaregiverSessionStatus.authenticated;
      notifyListeners();
      if (stored?.type == SessionType.caregiver) {
        FcmNotificationService.instance.register(this);
      }
    });
  }

  Future<void> login({
    required String householdCode,
    required String email,
    required String password,
  }) async {
    final revision = ++_revision;
    final token = await _authApi.login(
      householdCode: householdCode,
      email: email,
      password: password,
    );
    await _accept(
      StoredSession(
        token,
        SessionType.caregiver,
        householdCode: householdCode.trim(),
      ),
      revision,
    );
  }

  Future<void> accessPatient({required String accessCode}) async {
    final revision = ++_revision;
    final token = await _patientAuthApi.access(accessCode: accessCode);
    await _accept(StoredSession(token, SessionType.elderlyPatient), revision);
  }

  Future<void> _accept(StoredSession session, int revision) =>
      _serialize(() async {
        if (revision != _revision) return;
        try {
          await _tokenStore.writeSession(session);
        } catch (_) {
          try {
            await _tokenStore.clearSession();
          } catch (_) {
            /* Fail closed. */
          }
          rethrow;
        }
        if (revision != _revision) return;
        _session = session;
        _status = CaregiverSessionStatus.authenticated;
        notifyListeners();
        if (session.type == SessionType.caregiver) {
          FcmNotificationService.instance.register(this);
        }
      });

  Future<void> logout() async {
    ++_revision;
    await FcmNotificationService.instance.unregister(this);
    // Remove authenticated routes immediately, including while secure I/O runs.
    _session = null;
    _status = CaregiverSessionStatus.unauthenticated;
    notifyListeners();
    await _serialize(_tokenStore.clearSession);
  }

  @override
  Future<void> clearInvalidSession() => logout();
}
