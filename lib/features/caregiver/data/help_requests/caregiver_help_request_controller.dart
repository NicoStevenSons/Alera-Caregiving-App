import 'package:flutter/foundation.dart';

import '../../../help_requests/domain/help_request.dart';
import '../api/caregiver_help_request_api_data_source.dart';

enum CaregiverHelpRequestState { initialLoading, success, error }

class CaregiverHelpRequestController extends ChangeNotifier {
  CaregiverHelpRequestController({required this.dataSource});

  final CaregiverHelpRequestDataSource dataSource;

  CaregiverHelpRequestState _state = CaregiverHelpRequestState.initialLoading;
  List<HelpRequestRecord> _requests = const [];
  final Set<String> _busyRequestIds = {};
  String? _errorMessage;
  String? _actionErrorMessage;
  bool _refreshing = false;
  bool _disposed = false;
  int _revision = 0;

  CaregiverHelpRequestState get state => _state;
  List<HelpRequestRecord> get requests => List.unmodifiable(_requests);
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  bool get refreshing => _refreshing;
  bool get hasLoaded => _state != CaregiverHelpRequestState.initialLoading;
  bool isBusy(String requestId) => _busyRequestIds.contains(requestId);

  int get pendingCount => _requests
      .where((request) => request.status == HelpRequestStatus.pending)
      .length;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool refresh = false}) async {
    if (_disposed) return;

    final revision = ++_revision;

    if (refresh && hasLoaded) {
      _refreshing = true;
    } else {
      _state = CaregiverHelpRequestState.initialLoading;
    }

    _errorMessage = null;
    _notify();

    try {
      final byId = <String, HelpRequestRecord>{};
      var offset = 0;

      while (true) {
        final page = await dataSource.fetchRequests(
          statuses: const [
            HelpRequestStatus.pending,
            HelpRequestStatus.acknowledged,
          ],
          patientId: null,
          limit: 100,
          offset: offset,
        );

        if (_disposed || revision != _revision) return;

        if (page.offset != offset || page.total < 0) {
          throw const FormatException();
        }

        final previousCount = byId.length;

        for (final request in page.items) {
          if (request.status == HelpRequestStatus.pending ||
              request.status == HelpRequestStatus.acknowledged) {
            byId[request.id] = request;
          }
        }

        offset += page.items.length;

        if (offset >= page.total) break;

        if (page.items.isEmpty || byId.length == previousCount) {
          throw const FormatException();
        }
      }

      final requests = byId.values.toList()..sort(_compareRequests);

      _requests = List.unmodifiable(requests);
      _state = CaregiverHelpRequestState.success;
      _errorMessage = null;
    } on CaregiverHelpRequestFailure catch (error) {
      if (_disposed || revision != _revision) return;

      _errorMessage = error.message;

      if (_requests.isEmpty) {
        _state = CaregiverHelpRequestState.error;
      }
    } on FormatException {
      if (_disposed || revision != _revision) return;

      _errorMessage = 'Unable to load help requests. Please retry.';

      if (_requests.isEmpty) {
        _state = CaregiverHelpRequestState.error;
      }
    } finally {
      if (!_disposed && revision == _revision) {
        _refreshing = false;
        _notify();
      }
    }
  }

  Future<void> acknowledge(String requestId) {
    return _runAction(requestId, () => dataSource.acknowledge(requestId));
  }

  Future<void> resolve(String requestId) {
    return _runAction(requestId, () => dataSource.resolve(requestId));
  }

  Future<void> _runAction(
    String requestId,
    Future<HelpRequestRecord> Function() action,
  ) async {
    if (_disposed || _busyRequestIds.contains(requestId)) {
      return;
    }

    _busyRequestIds.add(requestId);
    _actionErrorMessage = null;
    _notify();

    try {
      final updated = await action();

      if (_disposed) return;

      if (updated.status == HelpRequestStatus.resolved) {
        _requests = List.unmodifiable(
          _requests.where((request) => request.id != requestId),
        );
      } else {
        final items = [..._requests];
        final index = items.indexWhere((request) => request.id == requestId);

        if (index >= 0) {
          items[index] = updated;
        } else {
          items.add(updated);
        }

        items.sort(_compareRequests);
        _requests = List.unmodifiable(items);
      }
    } on CaregiverHelpRequestFailure catch (error) {
      if (_disposed) return;

      _actionErrorMessage = error.message;

      if (error.statusCode == 409 || error.statusCode == 404) {
        await load(refresh: true);
      }
    } catch (_) {
      if (_disposed) return;

      _actionErrorMessage =
          'Unable to update this help request. Please try again.';
    } finally {
      if (!_disposed) {
        _busyRequestIds.remove(requestId);
        _notify();
      }
    }
  }

  static int _compareRequests(HelpRequestRecord a, HelpRequestRecord b) {
    final aPriority = a.status == HelpRequestStatus.pending ? 0 : 1;
    final bPriority = b.status == HelpRequestStatus.pending ? 0 : 1;

    final statusOrder = aPriority.compareTo(bPriority);
    if (statusOrder != 0) return statusOrder;

    final requestedOrder = a.requestedAt.compareTo(b.requestedAt);
    if (requestedOrder != 0) return requestedOrder;

    return a.id.compareTo(b.id);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    super.dispose();
  }
}
