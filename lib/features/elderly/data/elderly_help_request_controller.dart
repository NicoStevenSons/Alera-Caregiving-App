import 'package:flutter/foundation.dart';

import '../../help_requests/domain/help_request.dart';
import 'api/elderly_help_request_api_service.dart';

enum ElderlyHelpRequestState {
  initialLoading,
  available,
  sending,
  active,
  error,
}

class ElderlyHelpRequestController extends ChangeNotifier {
  ElderlyHelpRequestController({required this.dataSource});

  final ElderlyHelpRequestDataSource dataSource;

  ElderlyHelpRequestState _state = ElderlyHelpRequestState.initialLoading;
  HelpRequestRecord? _activeRequest;
  String? _errorMessage;
  String? _pendingActionId;
  bool _disposed = false;
  int _revision = 0;

  ElderlyHelpRequestState get state => _state;
  HelpRequestRecord? get activeRequest => _activeRequest;
  String? get errorMessage => _errorMessage;

  bool get loading => _state == ElderlyHelpRequestState.initialLoading;

  bool get sending => _state == ElderlyHelpRequestState.sending;

  bool get canRequestHelp =>
      _state == ElderlyHelpRequestState.available ||
      (_state == ElderlyHelpRequestState.error && _pendingActionId != null);

  bool get hasActiveRequest =>
      _state == ElderlyHelpRequestState.active && _activeRequest != null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (_disposed) return;

    final revision = ++_revision;

    _state = ElderlyHelpRequestState.initialLoading;
    _errorMessage = null;
    _notify();

    try {
      final request = await dataSource.fetchActive();

      if (_disposed || revision != _revision) return;

      _activeRequest = request;
      _pendingActionId = null;
      _state = request == null
          ? ElderlyHelpRequestState.available
          : ElderlyHelpRequestState.active;
    } on ElderlyHelpRequestApiFailure catch (error) {
      if (_disposed || revision != _revision) return;

      _activeRequest = null;
      _errorMessage = error.message;
      _state = ElderlyHelpRequestState.error;
    } catch (_) {
      if (_disposed || revision != _revision) return;

      _activeRequest = null;
      _errorMessage =
          'Unable to check your help-request status. Please try again.';
      _state = ElderlyHelpRequestState.error;
    } finally {
      if (!_disposed && revision == _revision) {
        _notify();
      }
    }
  }

  Future<void> requestHelp({String? message}) async {
    if (_disposed || sending || hasActiveRequest || !canRequestHelp) {
      return;
    }

    final revision = ++_revision;
    final actionId = _pendingActionId ??= dataSource.createActionId();

    _state = ElderlyHelpRequestState.sending;
    _errorMessage = null;
    _notify();

    try {
      final request = await dataSource.create(
        clientActionId: actionId,
        message: message,
      );

      if (_disposed || revision != _revision) return;

      _activeRequest = request;
      _pendingActionId = null;
      _state = ElderlyHelpRequestState.active;
    } on ElderlyHelpRequestApiFailure catch (error) {
      if (_disposed || revision != _revision) return;

      _errorMessage = error.message;
      _state = ElderlyHelpRequestState.error;
    } catch (_) {
      if (_disposed || revision != _revision) return;

      _errorMessage = 'Unable to request help. Please try again.';
      _state = ElderlyHelpRequestState.error;
    } finally {
      if (!_disposed && revision == _revision) {
        _notify();
      }
    }
  }

  Future<void> retry() {
    if (_pendingActionId != null) {
      return requestHelp();
    }

    return load();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    super.dispose();
  }
}
