import 'dart:async';

import 'package:alera/features/caregiver/data/api/caregiver_help_request_api_data_source.dart';
import 'package:alera/features/caregiver/data/help_requests/caregiver_help_request_controller.dart';
import 'package:alera/features/help_requests/domain/help_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads, paginates, and sorts longest-waiting pending first', () async {
    final source = _FakeHelpRequestDataSource()
      ..pages.addAll([
        HelpRequestPage(
          items: [
            _record(
              id: 'acknowledged',
              status: HelpRequestStatus.acknowledged,
              requestedAt: DateTime.utc(2026, 10, 5, 1),
            ),
            _record(
              id: 'newer-pending',
              requestedAt: DateTime.utc(2026, 10, 5, 3),
            ),
          ],
          total: 3,
          limit: 100,
          offset: 0,
        ),
        HelpRequestPage(
          items: [
            _record(
              id: 'older-pending',
              requestedAt: DateTime.utc(2026, 10, 5, 2),
            ),
          ],
          total: 3,
          limit: 100,
          offset: 2,
        ),
      ]);

    final controller = CaregiverHelpRequestController(dataSource: source);

    await controller.load();

    expect(source.fetchOffsets, [0, 2]);
    expect(controller.requests.map((item) => item.id), [
      'older-pending',
      'newer-pending',
      'acknowledged',
    ]);
    expect(controller.pendingCount, 2);
    expect(controller.state, CaregiverHelpRequestState.success);

    controller.dispose();
  });

  test('acknowledge updates and reorders the active request', () async {
    final source = _FakeHelpRequestDataSource()
      ..pages.add(
        _page([
          _record(id: 'first', requestedAt: DateTime.utc(2026, 10, 5, 1)),
          _record(id: 'second', requestedAt: DateTime.utc(2026, 10, 5, 2)),
        ]),
      )
      ..acknowledgeResponse = _record(
        id: 'first',
        status: HelpRequestStatus.acknowledged,
        requestedAt: DateTime.utc(2026, 10, 5, 1),
      );

    final controller = CaregiverHelpRequestController(dataSource: source);

    await controller.load();
    await controller.acknowledge('first');

    expect(source.acknowledgeCalls, ['first']);
    expect(controller.requests.map((item) => item.id), ['second', 'first']);
    expect(controller.requests.last.status, HelpRequestStatus.acknowledged);
    expect(controller.pendingCount, 1);

    controller.dispose();
  });

  test('resolve removes a terminal request from the active list', () async {
    final source = _FakeHelpRequestDataSource()
      ..pages.add(_page([_record(id: 'request')]))
      ..resolveResponse = _record(
        id: 'request',
        status: HelpRequestStatus.resolved,
      );

    final controller = CaregiverHelpRequestController(dataSource: source);

    await controller.load();
    await controller.resolve('request');

    expect(source.resolveCalls, ['request']);
    expect(controller.requests, isEmpty);

    controller.dispose();
  });

  test('duplicate action taps share the per-request busy guard', () async {
    final completion = Completer<HelpRequestRecord>();
    final source = _FakeHelpRequestDataSource()
      ..pages.add(_page([_record(id: 'request')]))
      ..acknowledgeFuture = completion.future;

    final controller = CaregiverHelpRequestController(dataSource: source);

    await controller.load();

    final first = controller.acknowledge('request');
    final second = controller.acknowledge('request');

    expect(controller.isBusy('request'), isTrue);
    expect(source.acknowledgeCalls, ['request']);

    completion.complete(
      _record(id: 'request', status: HelpRequestStatus.acknowledged),
    );

    await Future.wait([first, second]);

    expect(source.acknowledgeCalls, ['request']);
    expect(controller.isBusy('request'), isFalse);

    controller.dispose();
  });

  test('transition conflict refreshes from server truth', () async {
    final source = _FakeHelpRequestDataSource()
      ..pages.addAll([
        _page([_record(id: 'request')]),
        _page([_record(id: 'request', status: HelpRequestStatus.acknowledged)]),
      ])
      ..acknowledgeError = const CaregiverHelpRequestFailure(
        'This help request has already changed.',
        statusCode: 409,
      );

    final controller = CaregiverHelpRequestController(dataSource: source);

    await controller.load();
    await controller.acknowledge('request');

    expect(source.fetchOffsets, [0, 0]);
    expect(controller.requests.single.status, HelpRequestStatus.acknowledged);
    expect(
      controller.actionErrorMessage,
      'This help request has already changed.',
    );

    controller.dispose();
  });

  test('refresh failure keeps the last known active requests', () async {
    final source = _FakeHelpRequestDataSource()
      ..pages.add(_page([_record(id: 'request')]));

    final controller = CaregiverHelpRequestController(dataSource: source);

    await controller.load();

    source.fetchError = const CaregiverHelpRequestFailure(
      'Unable to reach Alera. Please try again.',
    );

    await controller.load(refresh: true);

    expect(controller.state, CaregiverHelpRequestState.success);
    expect(controller.requests.single.id, 'request');
    expect(controller.errorMessage, 'Unable to reach Alera. Please try again.');

    controller.dispose();
  });
}

class _FakeHelpRequestDataSource implements CaregiverHelpRequestDataSource {
  final List<HelpRequestPage> pages = [];
  final List<int> fetchOffsets = [];
  final List<String> acknowledgeCalls = [];
  final List<String> resolveCalls = [];

  Object? fetchError;
  Object? acknowledgeError;
  HelpRequestRecord? acknowledgeResponse;
  HelpRequestRecord? resolveResponse;
  Future<HelpRequestRecord>? acknowledgeFuture;

  @override
  Future<HelpRequestPage> fetchRequests({
    List<HelpRequestStatus> statuses = const [],
    String? patientId,
    int limit = 100,
    int offset = 0,
  }) async {
    fetchOffsets.add(offset);

    final error = fetchError;
    if (error != null) throw error;

    if (pages.isEmpty) {
      return const HelpRequestPage(items: [], total: 0, limit: 100, offset: 0);
    }

    return pages.removeAt(0);
  }

  @override
  Future<HelpRequestRecord> fetchRequest(String helpRequestId) async {
    return _record(id: helpRequestId);
  }

  @override
  Future<HelpRequestRecord> acknowledge(String helpRequestId) async {
    acknowledgeCalls.add(helpRequestId);

    final error = acknowledgeError;
    if (error != null) throw error;

    final future = acknowledgeFuture;
    if (future != null) return future;

    return acknowledgeResponse ??
        _record(id: helpRequestId, status: HelpRequestStatus.acknowledged);
  }

  @override
  Future<HelpRequestRecord> resolve(String helpRequestId) async {
    resolveCalls.add(helpRequestId);

    return resolveResponse ??
        _record(id: helpRequestId, status: HelpRequestStatus.resolved);
  }
}

HelpRequestPage _page(List<HelpRequestRecord> items) {
  return HelpRequestPage(
    items: items,
    total: items.length,
    limit: 100,
    offset: 0,
  );
}

HelpRequestRecord _record({
  required String id,
  HelpRequestStatus status = HelpRequestStatus.pending,
  DateTime? requestedAt,
}) {
  final requested = requestedAt ?? DateTime.utc(2026, 10, 5, 2);

  return HelpRequestRecord(
    id: id,
    patientId: 'patient-$id',
    status: status,
    message: 'Please call me',
    clientActionId: 'action-$id',
    requestedAt: requested,
    acknowledgedByUserId: status == HelpRequestStatus.acknowledged
        ? 'caregiver-id'
        : null,
    acknowledgedAt: status == HelpRequestStatus.acknowledged
        ? requested.add(const Duration(minutes: 1))
        : null,
    resolvedByUserId: status == HelpRequestStatus.resolved
        ? 'caregiver-id'
        : null,
    resolvedAt: status == HelpRequestStatus.resolved
        ? requested.add(const Duration(minutes: 2))
        : null,
    updatedAt: requested,
    patientDisplayName: 'Patient $id',
    idempotent: false,
  );
}
