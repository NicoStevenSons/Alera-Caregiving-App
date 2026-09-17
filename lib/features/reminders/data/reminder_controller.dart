import 'package:flutter/foundation.dart';

import '../domain/reminder_models.dart';
import 'reminder_api_data_source.dart';

class ReminderController extends ChangeNotifier {
  ReminderController({required ReminderDataSource dataSource})
    : _dataSource = dataSource;

  final ReminderDataSource _dataSource;
  List<ReminderOccurrence> _occurrences = const [];
  List<ReminderTemplate> _templates = const [];
  bool _loading = false;
  String? _errorMessage;
  String? _patientId;
  int _revision = 0;
  final Set<String> _busyOccurrenceIds = {};

  List<ReminderOccurrence> get occurrences => List.unmodifiable(_occurrences);
  List<ReminderTemplate> get templates => List.unmodifiable(_templates);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool isBusy(String occurrenceId) => _busyOccurrenceIds.contains(occurrenceId);

  Future<void> loadForPatient(String patientId) async {
    final revision = ++_revision;
    _patientId = patientId;
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _dataSource.fetchOccurrences(patientId: patientId),
        _dataSource.fetchTemplates(patientId),
      ]);
      if (revision != _revision || _patientId != patientId) return;
      _occurrences = (results[0] as ReminderPage<ReminderOccurrence>).items;
      _templates = (results[1] as ReminderPage<ReminderTemplate>).items;
    } on ReminderApiFailure catch (error) {
      if (revision != _revision) return;
      _errorMessage = error.message;
    } on FormatException {
      if (revision != _revision) return;
      _errorMessage = 'The reminder response was invalid.';
    } finally {
      if (revision == _revision) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    final patientId = _patientId;
    if (patientId != null) await loadForPatient(patientId);
  }

  Future<void> complete(String occurrenceId, {String? note}) =>
      _runAction(occurrenceId, () => _dataSource.complete(occurrenceId, note: note));

  Future<void> snooze(String occurrenceId, {int? minutes, String? note}) =>
      _runAction(
        occurrenceId,
        () => _dataSource.snooze(
          occurrenceId,
          snoozeMinutes: minutes,
          note: note,
        ),
      );

  Future<void> _runAction(
    String occurrenceId,
    Future<ReminderActionResult> Function() operation,
  ) async {
    if (_busyOccurrenceIds.contains(occurrenceId)) return;
    _busyOccurrenceIds.add(occurrenceId);
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await operation();
      final index = _occurrences.indexWhere((item) => item.id == occurrenceId);
      if (index >= 0) {
        final updated = [..._occurrences];
        updated[index] = result.reminder;
        _occurrences = updated;
      }
    } on ReminderApiFailure catch (error) {
      _errorMessage = error.message;
      rethrow;
    } finally {
      _busyOccurrenceIds.remove(occurrenceId);
      notifyListeners();
    }
  }

  void clear() {
    _revision++;
    _patientId = null;
    _occurrences = const [];
    _templates = const [];
    _loading = false;
    _errorMessage = null;
    _busyOccurrenceIds.clear();
    notifyListeners();
  }
}
