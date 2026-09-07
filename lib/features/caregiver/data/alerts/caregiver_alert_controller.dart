import 'package:flutter/foundation.dart';

import '../../domain/models/caregiver_alert.dart';
import '../api/caregiver_alert_api_data_source.dart';

class CaregiverAlertController extends ChangeNotifier {
  final CaregiverAlertDataSource loader;
  final CaregiverAlertActionDataSource? actions;
  final List<CaregiverAlert> _fallback;
  List<CaregiverAlert> _alerts = const [];
  final Set<String> _busyAlertIds = {};
  bool _hasLoaded = false;
  bool _loading = false;
  bool _showingFallback = false;

  CaregiverAlertController({
    required this.loader,
    this.actions,
    List<CaregiverAlert> fallback = const [],
  }) : _fallback = List.unmodifiable(fallback),
       _alerts = List.unmodifiable(fallback);

  List<CaregiverAlert> get alerts => List.unmodifiable(_alerts);
  bool get hasLoaded => _hasLoaded;
  bool get loading => _loading;
  bool get showingFallback => _showingFallback;
  bool isBusy(String alertId) => _busyAlertIds.contains(alertId);
  bool get supportsActions => actions != null;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      _alerts = await loader.fetchAlerts();
      _showingFallback = false;
    } on CaregiverAlertsTimeoutFailure {
      _alerts = _fallback;
      _showingFallback = true;
    } on CaregiverAlertsRequestFailure {
      _alerts = _fallback;
      _showingFallback = true;
    } on CaregiverAlertsHttpFailure catch (failure) {
      if (failure.statusCode >= 500) {
        _alerts = _fallback;
        _showingFallback = true;
      } else {
        _alerts = const [];
        _showingFallback = false;
      }
    } catch (_) {
      _alerts = const [];
      _showingFallback = false;
    } finally {
      _loading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  void upsert(CaregiverAlert alert) {
    final index = _alerts.indexWhere((item) => item.id == alert.id);
    if (index < 0) {
      _alerts = [alert, ..._alerts];
    } else {
      final updated = [..._alerts];
      updated[index] = alert;
      _alerts = updated;
    }
    notifyListeners();
  }

  Future<CaregiverAlert> acknowledge(String alertId, {String? note}) =>
      _run(alertId, (actions) => actions.acknowledge(alertId, note: note));

  Future<CaregiverAlert> resolve(String alertId, {String? note}) =>
      _run(alertId, (actions) => actions.resolve(alertId, note: note));

  Future<CaregiverAlert> markFalseAlarm(String alertId, String reason) =>
      _run(alertId, (actions) => actions.markFalseAlarm(alertId, reason));

  Future<CaregiverAlert> addNote(String alertId, String note) =>
      _run(alertId, (actions) => actions.addNote(alertId, note));

  Future<CaregiverAlert> logIntervention(
    String alertId,
    CaregiverInterventionType type,
    String note,
  ) => _run(alertId, (actions) => actions.logIntervention(alertId, type, note));

  Future<CaregiverAlert> _run(
    String alertId,
    Future<CaregiverAlert> Function(CaregiverAlertActionDataSource) operation,
  ) async {
    final actionSource = actions;
    if (actionSource == null || !_busyAlertIds.add(alertId)) {
      throw const CaregiverAlertActionFailure();
    }
    notifyListeners();
    try {
      final updated = await operation(actionSource);
      upsert(updated);
      return updated;
    } finally {
      _busyAlertIds.remove(alertId);
      notifyListeners();
    }
  }
}

class CaregiverAlertActionFailure implements Exception {
  const CaregiverAlertActionFailure();
}
