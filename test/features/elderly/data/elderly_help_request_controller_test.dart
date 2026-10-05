import 'dart:async';

import 'package:alera/features/elderly/data/api/elderly_help_request_api_service.dart';
import 'package:alera/features/elderly/data/elderly_help_request_controller.dart';
import 'package:alera/features/elderly/domain/models/elderly_help_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'load exposes an available request action when none is active',
    () async {
      final source = _FakeHelpRequestDataSource();
      final controller = ElderlyHelpRequestController(dataSource: source);

      await controller.load();

      expect(source.fetchCalls, 1);
      expect(controller.state, ElderlyHelpRequestState.available);
      expect(controller.canRequestHelp, isTrue);
      expect(controller.activeRequest, isNull);

      controller.dispose();
    },
  );

  test('load restores an existing active help request', () async {
    final source = _FakeHelpRequestDataSource()..activeResponse = _request();
    final controller = ElderlyHelpRequestController(dataSource: source);

    await controller.load();

    expect(controller.state, ElderlyHelpRequestState.active);
    expect(controller.hasActiveRequest, isTrue);
    expect(controller.canRequestHelp, isFalse);
    expect(controller.activeRequest?.id, 'help-request-id');

    controller.dispose();
  });

  test('requestHelp creates one request and exposes active state', () async {
    final source = _FakeHelpRequestDataSource()..createResponse = _request();
    final controller = ElderlyHelpRequestController(dataSource: source);

    await controller.load();
    await controller.requestHelp(message: 'Please call me');

    expect(source.createCalls, 1);
    expect(source.actionIds, ['action-id']);
    expect(source.messages, ['Please call me']);
    expect(controller.state, ElderlyHelpRequestState.active);
    expect(controller.hasActiveRequest, isTrue);

    controller.dispose();
  });

  test('retry reuses the same action id after an uncertain failure', () async {
    final source = _FakeHelpRequestDataSource()
      ..createError = const ElderlyHelpRequestApiFailure(
        'Unable to reach Alera. Please try again.',
      );
    final controller = ElderlyHelpRequestController(dataSource: source);

    await controller.load();
    await controller.requestHelp();

    expect(controller.state, ElderlyHelpRequestState.error);
    expect(controller.canRequestHelp, isTrue);
    expect(source.actionIds, ['action-id']);

    source
      ..createError = null
      ..createResponse = _request(idempotent: true);

    await controller.retry();

    expect(source.actionIds, ['action-id', 'action-id']);
    expect(controller.state, ElderlyHelpRequestState.active);
    expect(controller.activeRequest?.idempotent, isTrue);

    controller.dispose();
  });

  test('load failure retries the status check rather than creating', () async {
    final source = _FakeHelpRequestDataSource()
      ..fetchError = const ElderlyHelpRequestApiFailure(
        'Unable to reach Alera. Please try again.',
      );
    final controller = ElderlyHelpRequestController(dataSource: source);

    await controller.load();

    expect(controller.state, ElderlyHelpRequestState.error);
    expect(controller.errorMessage, 'Unable to reach Alera. Please try again.');

    source.fetchError = null;
    await controller.retry();

    expect(source.fetchCalls, 2);
    expect(source.createCalls, 0);
    expect(controller.state, ElderlyHelpRequestState.available);

    controller.dispose();
  });

  test('duplicate taps cannot create concurrent help requests', () async {
    final completion = Completer<ElderlyHelpRequest>();
    final source = _FakeHelpRequestDataSource()
      ..createFuture = completion.future;
    final controller = ElderlyHelpRequestController(dataSource: source);

    await controller.load();

    final first = controller.requestHelp();
    final second = controller.requestHelp();

    expect(controller.sending, isTrue);
    expect(source.createCalls, 1);

    completion.complete(_request());
    await Future.wait([first, second]);

    expect(source.createCalls, 1);
    expect(controller.state, ElderlyHelpRequestState.active);

    controller.dispose();
  });
}

class _FakeHelpRequestDataSource implements ElderlyHelpRequestDataSource {
  int fetchCalls = 0;
  int createCalls = 0;

  ElderlyHelpRequest? activeResponse;
  ElderlyHelpRequest? createResponse;
  Future<ElderlyHelpRequest>? createFuture;
  Object? fetchError;
  Object? createError;

  final List<String> actionIds = [];
  final List<String?> messages = [];

  @override
  String createActionId() => 'action-id';

  @override
  Future<ElderlyHelpRequest?> fetchActive() async {
    fetchCalls++;

    final error = fetchError;
    if (error != null) throw error;

    return activeResponse;
  }

  @override
  Future<ElderlyHelpRequest> create({
    required String clientActionId,
    String? message,
  }) async {
    createCalls++;
    actionIds.add(clientActionId);
    messages.add(message);

    final error = createError;
    if (error != null) throw error;

    final pending = createFuture;
    if (pending != null) return pending;

    return createResponse ?? _request();
  }
}

ElderlyHelpRequest _request({bool idempotent = false}) {
  return ElderlyHelpRequest(
    id: 'help-request-id',
    patientId: 'patient-id',
    status: ElderlyHelpRequestStatus.pending,
    message: 'Please call me',
    clientActionId: 'action-id',
    requestedAt: DateTime.utc(2026, 10, 5, 2),
    acknowledgedByUserId: null,
    acknowledgedAt: null,
    resolvedByUserId: null,
    resolvedAt: null,
    updatedAt: DateTime.utc(2026, 10, 5, 2),
    patientDisplayName: 'Test Patient',
    idempotent: idempotent,
  );
}
