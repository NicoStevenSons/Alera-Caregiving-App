import 'package:flutter/foundation.dart';

import '../domain/reminder_models.dart';
import 'reminder_api_data_source.dart';

class ReminderController extends ChangeNotifier {
  ReminderController({required this.dataSource});

  final ReminderDataSource dataSource;
  List<ReminderOccurrence> _occurrences = const [];
  List<ReminderTemplate> _templates = const [];
  bool _loading = false;
  bool _disposed = false;
  String? _errorMessage;
  String? _patientId;
  int _revision = 0;
  int _patientRevision = 0;
  final Set<String> _busyOccurrenceIds = {};
  final Set<String> _busyTemplateIds = {};

  List<ReminderOccurrence> get occurrences => List.unmodifiable(_occurrences);
  List<ReminderTemplate> get templates => List.unmodifiable(_templates);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool isBusy(String occurrenceId) => _busyOccurrenceIds.contains(occurrenceId);
  bool isTemplateBusy(String templateId) =>
      _busyTemplateIds.contains(templateId);

  bool _isCurrentPatient(int revision) =>
      !_disposed && revision == _patientRevision;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadForPatient(String patientId) async {
    if (_disposed) return;
    final revision = ++_revision;
    if (_patientId != patientId) {
      ++_patientRevision;
      _occurrences = const [];
      _templates = const [];
      _busyOccurrenceIds.clear();
      _busyTemplateIds.clear();
    }
    _patientId = patientId;
    _loading = true;
    _errorMessage = null;
    _notify();
    try {
      final results = await Future.wait([
        dataSource.fetchOccurrences(patientId: patientId),
        dataSource.fetchTemplates(patientId),
      ]);
      if (_disposed || revision != _revision || _patientId != patientId) return;
      _occurrences = (results[0] as ReminderPage<ReminderOccurrence>).items;
      _templates = (results[1] as ReminderPage<ReminderTemplate>).items;
    } on ReminderApiFailure catch (error) {
      if (_disposed || revision != _revision) return;
      _errorMessage = error.message;
    } on FormatException {
      if (_disposed || revision != _revision) return;
      _errorMessage = 'The reminder response was invalid.';
    } finally {
      if (!_disposed && revision == _revision) {
        _loading = false;
        _notify();
      }
    }
  }

  Future<void> refresh() async {
    final patientId = _patientId;
    if (!_disposed && patientId != null) await loadForPatient(patientId);
  }

  Future<void> complete(String occurrenceId, {String? note}) => _runAction(
    occurrenceId,
    () => dataSource.complete(occurrenceId, note: note),
  );

  Future<void> snooze(String occurrenceId, {int? minutes, String? note}) =>
      _runAction(
        occurrenceId,
        () =>
            dataSource.snooze(occurrenceId, snoozeMinutes: minutes, note: note),
      );

  Future<void> completeOnBehalf(String occurrenceId, String note) => _runAction(
    occurrenceId,
    () => dataSource.completeOnBehalf(occurrenceId, note),
  );

  Future<void> cancel(String occurrenceId, String note) =>
      _runAction(occurrenceId, () => dataSource.cancel(occurrenceId, note));

  Future<void> snoozeOnBehalf(
    String occurrenceId,
    String note, {
    int? minutes,
  }) => _runAction(
    occurrenceId,
    () => dataSource.snoozeOnBehalf(occurrenceId, note, snoozeMinutes: minutes),
  );

  Future<void> createTemplate(ReminderTemplateDraft draft) async {
    if (_disposed) return;
    final revision = _patientRevision;
    final appliesToCurrentPatient = draft.patientId == _patientId;
    if (appliesToCurrentPatient) {
      _errorMessage = null;
      _notify();
    }
    try {
      final created = await dataSource.createTemplate(draft);
      if (!appliesToCurrentPatient || !_isCurrentPatient(revision)) return;
      _templates = [created, ..._templates];
      await refresh();
    } on ReminderApiFailure catch (error) {
      if (appliesToCurrentPatient && _isCurrentPatient(revision)) {
        _errorMessage = error.message;
        _notify();
      }
      rethrow;
    }
  }

  Future<void> archiveTemplate(String templateId) async {
    if (_disposed || _busyTemplateIds.contains(templateId)) return;
    final revision = _patientRevision;
    _busyTemplateIds.add(templateId);
    _errorMessage = null;
    _notify();
    try {
      final archived = await dataSource.archiveTemplate(templateId);
      if (!_isCurrentPatient(revision)) return;
      final index = _templates.indexWhere((item) => item.id == templateId);
      if (index >= 0) {
        final updated = [..._templates];
        updated[index] = archived;
        _templates = updated;
      }
      await refresh();
    } on ReminderApiFailure catch (error) {
      if (_isCurrentPatient(revision)) _errorMessage = error.message;
      rethrow;
    } finally {
      if (_isCurrentPatient(revision)) {
        _busyTemplateIds.remove(templateId);
        _notify();
      }
    }
  }

  Future<void> _runAction(
    String occurrenceId,
    Future<ReminderActionResult> Function() operation,
  ) async {
    if (_disposed || _busyOccurrenceIds.contains(occurrenceId)) return;
    final revision = _patientRevision;
    _busyOccurrenceIds.add(occurrenceId);
    _errorMessage = null;
    _notify();
    try {
      final result = await operation();
      if (!_isCurrentPatient(revision)) return;
      final index = _occurrences.indexWhere((item) => item.id == occurrenceId);
      if (index >= 0) {
        final updated = [..._occurrences];
        updated[index] = result.reminder;
        _occurrences = updated;
      }
    } on ReminderApiFailure catch (error) {
      if (_isCurrentPatient(revision)) _errorMessage = error.message;
      rethrow;
    } finally {
      if (_isCurrentPatient(revision)) {
        _busyOccurrenceIds.remove(occurrenceId);
        _notify();
      }
    }
  }

  void clear() {
    if (_disposed) return;
    ++_revision;
    ++_patientRevision;
    _patientId = null;
    _occurrences = const [];
    _templates = const [];
    _loading = false;
    _errorMessage = null;
    _busyOccurrenceIds.clear();
    _busyTemplateIds.clear();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    ++_patientRevision;
    super.dispose();
  }
}
