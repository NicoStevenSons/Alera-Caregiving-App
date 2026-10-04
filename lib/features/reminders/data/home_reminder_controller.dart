import 'package:flutter/foundation.dart';

import '../domain/reminder_models.dart';
import 'reminder_api_data_source.dart';

/// Returns Manila midnight as a UTC instant, regardless of the phone timezone.
DateTime manilaDayStartUtc(DateTime instant) {
  final manila = instant.toUtc().add(const Duration(hours: 8));
  return DateTime.utc(
    manila.year,
    manila.month,
    manila.day,
  ).subtract(const Duration(hours: 8));
}

class HomeReminderController extends ChangeNotifier {
  HomeReminderController({required this.dataSource, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ReminderDateRangeDataSource dataSource;
  final DateTime Function() _now;
  List<ReminderOccurrence> _occurrences = const [];
  String? _patientId;
  DateTime? _dayStart;
  bool _loading = false;
  bool _hasLoaded = false;
  bool _disposed = false;
  String? _errorMessage;
  int _revision = 0;

  List<ReminderOccurrence> get occurrences => List.unmodifiable(_occurrences);
  String? get patientId => _patientId;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  Future<void> ensureLoaded(String patientId) async {
    if (_disposed) return;
    final day = manilaDayStartUtc(_now());
    if (_patientId == patientId && _dayStart == day) return;
    await loadForPatient(patientId);
  }

  Future<void> loadForPatient(String patientId) async {
    if (_disposed) return;
    final revision = ++_revision;
    final start = manilaDayStartUtc(_now());
    final end = start.add(const Duration(days: 1));
    final sameContext = _patientId == patientId && _dayStart == start;
    if (!sameContext) {
      _occurrences = const [];
      _hasLoaded = false;
    }
    _patientId = patientId;
    _dayStart = start;
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final byId = <String, ReminderOccurrence>{};
      var offset = 0;
      while (true) {
        final page = await dataSource.fetchOccurrencesInRange(
          patientId: patientId,
          fromAt: start,
          beforeAt: end,
          limit: 100,
          offset: offset,
        );
        if (_disposed || revision != _revision) return;

        if (page.offset != offset || page.total < 0) {
          throw const FormatException();
        }
        final previousCount = byId.length;
        for (final occurrence in page.items) {
          final scheduled = occurrence.scheduledAt.toUtc();
          if (occurrence.patientId != patientId ||
              scheduled.isBefore(start) ||
              !scheduled.isBefore(end)) {
            throw const FormatException();
          }
          byId[occurrence.id] = occurrence;
        }
        offset += page.items.length;
        if (offset >= page.total) break;
        if (page.items.isEmpty || byId.length == previousCount) {
          throw const FormatException();
        }
      }

      final items = byId.values.toList()
        ..sort((a, b) {
          final time = a.scheduledAt.compareTo(b.scheduledAt);
          return time != 0 ? time : a.id.compareTo(b.id);
        });
      _occurrences = List.unmodifiable(items);
    } on ReminderApiFailure catch (error) {
      if (!_disposed && revision == _revision) {
        _errorMessage = error.message;
      }
    } on FormatException {
      if (!_disposed && revision == _revision) {
        _errorMessage = 'Unable to load today’s reminders. Please retry.';
      }
    } catch (_) {
      if (!_disposed && revision == _revision) {
        _errorMessage = 'Unable to load today’s reminders. Please retry.';
      }
    } finally {
      if (!_disposed && revision == _revision) {
        _loading = false;
        _hasLoaded = true;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    final patientId = _patientId;
    if (patientId != null) await loadForPatient(patientId);
  }

  void clear() {
    if (_disposed) return;
    ++_revision;
    _patientId = null;
    _dayStart = null;
    _hasLoaded = false;
    _occurrences = const [];
    _loading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    super.dispose();
  }
}
