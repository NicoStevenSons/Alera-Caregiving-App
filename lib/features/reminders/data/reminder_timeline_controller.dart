import 'package:flutter/foundation.dart';

import '../domain/reminder_event.dart';
import 'reminder_api_data_source.dart';

/// Loads and paginates the history of one reminder occurrence. Events stay
/// in the order the backend returns them (oldest first); "load more" appends.
class ReminderTimelineController extends ChangeNotifier {
  ReminderTimelineController({
    required ReminderEventsDataSource dataSource,
    required this.occurrenceId,
    this.pageSize = 50,
  }) : _dataSource = dataSource;

  final ReminderEventsDataSource _dataSource;
  final String occurrenceId;
  final int pageSize;

  List<ReminderEvent> _events = const [];
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _loaded = false;
  bool _notFound = false;
  String? _errorMessage;
  String? _loadMoreError;
  int _generation = 0;
  bool _disposed = false;

  List<ReminderEvent> get events => _events;
  int get total => _total;

  /// First page in flight (nothing to show yet).
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;

  /// The first page failed; show a retry state.
  String? get errorMessage => _errorMessage;

  /// A later page failed; keep what is shown and offer to retry.
  String? get loadMoreError => _loadMoreError;

  /// The backend answered 404: the reminder is gone or not visible.
  bool get notFound => _notFound;
  bool get isEmpty => _loaded && _events.isEmpty && _errorMessage == null;
  bool get hasMore => _loaded && _events.length < _total;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// (Re)loads the first page. Safe to call again for retry or after an
  /// action changed the history.
  Future<void> load() async {
    final generation = ++_generation;
    _loading = true;
    _loadingMore = false;
    _errorMessage = null;
    _loadMoreError = null;
    _notFound = false;
    _notify();
    try {
      final page = await _dataSource.fetchEvents(
        occurrenceId,
        limit: pageSize,
        offset: 0,
      );
      if (generation != _generation) return;
      _events = List.unmodifiable(page.items);
      _total = page.total;
      _loaded = true;
    } on ReminderApiFailure catch (error) {
      if (generation != _generation) return;
      _notFound = error.statusCode == 404;
      _errorMessage = error.message;
    } catch (_) {
      if (generation != _generation) return;
      _errorMessage = 'Unable to load the history. Please try again.';
    }
    if (generation == _generation) {
      _loading = false;
      _notify();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || _loading || _loadingMore) return;
    final generation = _generation;
    _loadingMore = true;
    _loadMoreError = null;
    _notify();
    try {
      final page = await _dataSource.fetchEvents(
        occurrenceId,
        limit: pageSize,
        offset: _events.length,
      );
      if (generation != _generation) return;
      final known = _events.map((event) => event.id).toSet();
      _events = List.unmodifiable([
        ..._events,
        ...page.items.where((event) => !known.contains(event.id)),
      ]);
      _total = page.total;
      // A page with nothing new would otherwise leave "Load more" forever.
      if (page.items.isEmpty) _total = _events.length;
    } on ReminderApiFailure catch (error) {
      if (generation != _generation) return;
      _loadMoreError = error.message;
    } catch (_) {
      if (generation != _generation) return;
      _loadMoreError = 'Unable to load more. Please try again.';
    }
    if (generation == _generation) {
      _loadingMore = false;
      _notify();
    }
  }
}
