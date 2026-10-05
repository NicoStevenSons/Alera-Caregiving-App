import 'dart:async';

import 'package:alera/features/caregiver/data/api/caregiver_help_request_api_data_source.dart';
import 'package:alera/features/caregiver/data/help_requests/caregiver_help_request_controller.dart';
import 'package:alera/features/caregiver/presentation/home/widgets/home_help_requests_preview.dart';
import 'package:alera/features/help_requests/domain/help_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading while active requests are checked', (
    tester,
  ) async {
    final completion = Completer<HelpRequestPage>();
    final source = _FakeHelpRequestDataSource()
      ..fetchFuture = completion.future;
    final controller = CaregiverHelpRequestController(dataSource: source);
    addTearDown(controller.dispose);

    final load = controller.load();
    await _pump(tester, controller);

    expect(find.byKey(const Key('home-help-requests-loading')), findsOneWidget);

    completion.complete(_page(const []));
    await load;
    await tester.pump();

    expect(find.byKey(const Key('home-help-requests-empty')), findsOneWidget);
  });

  testWidgets('pending request can be acknowledged', (tester) async {
    final source = _FakeHelpRequestDataSource()
      ..pages.add(_page([_record(id: 'request')]))
      ..acknowledgeResponse = _record(
        id: 'request',
        status: HelpRequestStatus.acknowledged,
      );

    final controller = CaregiverHelpRequestController(dataSource: source);
    addTearDown(controller.dispose);

    await controller.load();
    await _pump(tester, controller);

    expect(find.text('Nana'), findsOneWidget);
    expect(find.text('Please call me'), findsOneWidget);
    expect(find.byKey(const Key('home-help-requests-badge')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('acknowledge-help-request')),
    );
    await tester.pump();
    await tester.pump();

    expect(source.acknowledgeCalls, ['request']);
    expect(find.text('Acknowledged · 10:00 AM'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('acknowledge-help-request')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('resolve-help-request')),
      findsOneWidget,
    );
  });

  testWidgets('resolving removes the request from active Home', (tester) async {
    final source = _FakeHelpRequestDataSource()
      ..pages.add(
        _page([_record(id: 'request', status: HelpRequestStatus.acknowledged)]),
      )
      ..resolveResponse = _record(
        id: 'request',
        status: HelpRequestStatus.resolved,
      );

    final controller = CaregiverHelpRequestController(dataSource: source);
    addTearDown(controller.dispose);

    await controller.load();
    await _pump(tester, controller);

    await tester.tap(
      find.byKey(const ValueKey<String>('resolve-help-request')),
    );
    await tester.pump();
    await tester.pump();

    expect(source.resolveCalls, ['request']);
    expect(find.byKey(const Key('home-help-requests-empty')), findsOneWidget);
  });

  testWidgets('load failure explains itself and retries', (tester) async {
    final source = _FakeHelpRequestDataSource()
      ..fetchError = const CaregiverHelpRequestFailure(
        'Unable to reach Alera. Please try again.',
      );
    final controller = CaregiverHelpRequestController(dataSource: source);
    addTearDown(controller.dispose);

    await controller.load();
    await _pump(tester, controller);

    expect(find.byKey(const Key('home-help-requests-error')), findsOneWidget);
    expect(
      find.text('Unable to reach Alera. Please try again.'),
      findsOneWidget,
    );

    source
      ..fetchError = null
      ..pages.add(_page([_record(id: 'request')]));

    await tester.tap(find.byKey(const Key('home-help-requests-retry')));
    await tester.pump();
    await tester.pump();

    expect(source.fetchCalls, 2);
    expect(find.text('Nana'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  CaregiverHelpRequestController controller,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeHelpRequestsPreview(controller: controller),
        ),
      ),
    ),
  );
}

class _FakeHelpRequestDataSource implements CaregiverHelpRequestDataSource {
  final List<HelpRequestPage> pages = [];
  final List<String> acknowledgeCalls = [];
  final List<String> resolveCalls = [];

  int fetchCalls = 0;
  Object? fetchError;
  Future<HelpRequestPage>? fetchFuture;
  HelpRequestRecord? acknowledgeResponse;
  HelpRequestRecord? resolveResponse;

  @override
  Future<HelpRequestPage> fetchRequests({
    List<HelpRequestStatus> statuses = const [],
    String? patientId,
    int limit = 100,
    int offset = 0,
  }) async {
    fetchCalls++;

    final error = fetchError;
    if (error != null) throw error;

    final future = fetchFuture;
    if (future != null) return future;

    if (pages.isEmpty) return _page(const []);
    return pages.removeAt(0);
  }

  @override
  Future<HelpRequestRecord> fetchRequest(String helpRequestId) async {
    return _record(id: helpRequestId);
  }

  @override
  Future<HelpRequestRecord> acknowledge(String helpRequestId) async {
    acknowledgeCalls.add(helpRequestId);

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
}) {
  final requested = DateTime(2026, 10, 5, 10);

  return HelpRequestRecord(
    id: id,
    patientId: 'patient-id',
    status: status,
    message: 'Please call me',
    clientActionId: 'action-id',
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
    patientDisplayName: 'Nana',
    idempotent: false,
  );
}
