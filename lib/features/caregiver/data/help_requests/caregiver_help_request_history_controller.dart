import 'package:flutter/foundation.dart';

import '../../../help_requests/domain/help_request.dart';
import '../api/caregiver_help_request_api_data_source.dart';

enum HelpRequestHistoryFilter { active, resolved }

enum HelpRequestHistoryState { initialLoading, success, error }

class CaregiverHelpRequestHistoryController extends ChangeNotifier {
  CaregiverHelpRequestHistoryController({required this.dataSource});

  final CaregiverHelpRequestDataSource dataSource;

  HelpRequestHistoryFilter _filter = HelpRequestHistoryFilter.active;
  HelpRequestHistoryState _state = HelpRequestHistoryState.initialLoading;
  List<HelpRequestRecord> _requests = const [];
  String? _errorMessage;
  bool _disposed = false;
  int _revision = 0;

  HelpRequestHistoryFilter get filter => _filter;
  HelpRequestHistoryState get state => _state;
  List<HelpRequestRecord> get requests => List.unmodifiable(_requests);
  String? get errorMessage => _errorMessage;

  Future<void> selectFilter(HelpRequestHistoryFilter filter) {
    if (_filter == filter && _state != HelpRequestHistoryState.error) {
      return Future<void>.value();
    }

    _filter = filter;
    return load();
  }

  Future<void> load() async {
    if (_disposed) return;

    final revision = ++_revision;
    _state = HelpRequestHistoryState.initialLoading;
    _errorMessage = null;
    _notify();

    try {
      final byId = <String, HelpRequestRecord>{};
      var offset = 0;

      while (true) {
        final page = await dataSource.fetchRequests(
          statuses: _statusesFor(_filter),
          limit: 100,
          offset: offset,
        );

        if (_disposed || revision != _revision) return;

        if (page.offset != offset || page.total < 0) {
          throw const FormatException();
        }

        for (final request in page.items) {
          if (!_matchesFilter(request, _filter)) {
            throw const FormatException();
          }

          byId[request.id] = request;
        }

        offset += page.items.length;

        if (offset >= page.total) break;
        if (page.items.isEmpty) throw const FormatException();
      }

      final requests = byId.values.toList()
        ..sort((a, b) {
          final requestedOrder = b.requestedAt.compareTo(a.requestedAt);
          if (requestedOrder != 0) return requestedOrder;
          return b.id.compareTo(a.id);
        });

      _requests = List.unmodifiable(requests);
      _state = HelpRequestHistoryState.success;
    } on CaregiverHelpRequestFailure catch (error) {
      if (_disposed || revision != _revision) return;

      _errorMessage = error.message;
      _state = HelpRequestHistoryState.error;
    } on FormatException {
      if (_disposed || revision != _revision) return;

      _errorMessage = 'Unable to load help-request history. Please retry.';
      _state = HelpRequestHistoryState.error;
    } catch (_) {
      if (_disposed || revision != _revision) return;

      _errorMessage = 'Unable to load help-request history. Please retry.';
      _state = HelpRequestHistoryState.error;
    } finally {
      if (!_disposed && revision == _revision) _notify();
    }
  }

  static List<HelpRequestStatus> _statusesFor(HelpRequestHistoryFilter filter) {
    return switch (filter) {
      HelpRequestHistoryFilter.active => const [
        HelpRequestStatus.pending,
        HelpRequestStatus.acknowledged,
      ],
      HelpRequestHistoryFilter.resolved => const [HelpRequestStatus.resolved],
    };
  }

  static bool _matchesFilter(
    HelpRequestRecord request,
    HelpRequestHistoryFilter filter,
  ) {
    return switch (filter) {
      HelpRequestHistoryFilter.active =>
        request.status == HelpRequestStatus.pending ||
            request.status == HelpRequestStatus.acknowledged,
      HelpRequestHistoryFilter.resolved =>
        request.status == HelpRequestStatus.resolved,
    };
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    super.dispose();
  }
}
