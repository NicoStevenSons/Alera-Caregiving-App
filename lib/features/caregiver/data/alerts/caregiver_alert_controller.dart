import 'package:flutter/foundation.dart';

import '../../domain/models/caregiver_alert.dart';
import '../api/caregiver_alert_api_data_source.dart';

class CaregiverAlertController extends ChangeNotifier {
  final CaregiverAlertDataSource loader;
  final CaregiverAlertActionDataSource? actions;
  final CaregiverAlertTimelineDataSource? timelineSource;
  final List<CaregiverAlert> _fallback;
  List<CaregiverAlert> _alerts = const [];
  final Set<String> _busyAlertIds = {};
  bool _hasLoaded = false;
  bool _loading = false;
  bool _showingFallback = false;

  CaregiverAlertController({
    required this.loader,
    this.actions,
    this.timelineSource,
    List<CaregiverAlert> fallback = const [],
  }) : _fallback = List.unmodifiable(fallback),
       _alerts = List.unmodifiable(fallback);

  List<CaregiverAlert> get alerts => List.unmodifiable(_alerts);
  bool get hasLoaded => _hasLoaded;
  bool get loading => _loading;
  bool get showingFallback => _showingFallback;
  bool isBusy(String alertId) => _busyAlertIds.contains(alertId);
  bool get supportsActions => actions != null;

  Future<List<AlertTimelineEntry>> loadTimeline(String alertId) async {
    final source = timelineSource;
    if (source == null) return const [];
    final timeline = await source.fetchTimeline(alertId);
    final index = _alerts.indexWhere((item) => item.id == alertId);
    if (index >= 0) upsert(_alerts[index].copyWith(timeline: timeline));
    return timeline;
  }

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
    } on CaregiverAlertsParseFailure catch (failure) {
      debugPrint('Failed to parse caregiver alerts: $failure');
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
    } catch (error) {
      debugPrint('Unexpected caregiver alert load failure: $error');
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

  Future<CaregiverAlert> acknowledge(String alertId, {String? note}) => _run(
    alertId,
    (actions) => actions.acknowledge(alertId, note: note),
    optimisticStatus: CaregiverAlertStatus.acknowledged,
  );

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
    Future<CaregiverAlert> Function(CaregiverAlertActionDataSource) operation, {
    CaregiverAlertStatus? optimisticStatus,
  }) async {
    final actionSource = actions;
    if (actionSource == null || !_busyAlertIds.add(alertId)) {
      throw const CaregiverAlertActionFailure();
    }

    final previousIndex = _alerts.indexWhere((item) => item.id == alertId);
    final previous = previousIndex < 0 ? null : _alerts[previousIndex];
    if (optimisticStatus != null && previous != null) {
      final optimistic = [..._alerts];
      optimistic[previousIndex] = previous.copyWith(status: optimisticStatus);
      _alerts = optimistic;
    }
    notifyListeners();

    var actionCompleted = false;
    try {
      final updated = await operation(actionSource);
      actionCompleted = true;
      final existingIndex = _alerts.indexWhere((item) => item.id == alertId);
      final existing = existingIndex < 0 ? null : _alerts[existingIndex];
      var hydrated = existing == null
          ? updated
          : existing.copyWith(
              severity: updated.severity,
              status: updated.status,
              resolvedAt: updated.resolvedAt,
              timeline: updated.timeline.isEmpty
                  ? existing.timeline
                  : updated.timeline,
              note: updated.note ?? existing.note,
            );
      final source = timelineSource;
      if (source != null) {
        try {
          hydrated = hydrated.copyWith(
            timeline: await source.fetchTimeline(alertId),
          );
        } catch (_) {
          // Timeline hydration is secondary to a successful lifecycle action.
        }
      }
      upsert(hydrated);
      return hydrated;
    } catch (_) {
      if (!actionCompleted && previous != null && optimisticStatus != null) {
        final currentIndex = _alerts.indexWhere((item) => item.id == alertId);
        if (currentIndex >= 0 &&
            _alerts[currentIndex].status == optimisticStatus) {
          final rolledBack = [..._alerts];
          rolledBack[currentIndex] = previous;
          _alerts = rolledBack;
          notifyListeners();
        }
      }
      rethrow;
    } finally {
      _busyAlertIds.remove(alertId);
      notifyListeners();
    }
  }
}

class CaregiverAlertActionFailure implements Exception {
  const CaregiverAlertActionFailure();
}
