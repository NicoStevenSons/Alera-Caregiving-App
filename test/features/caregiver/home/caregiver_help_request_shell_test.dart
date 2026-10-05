import 'package:alera/features/caregiver/caregiver_shell.dart';
import 'package:alera/features/caregiver/data/api/caregiver_help_request_api_data_source.dart';
import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:alera/features/help_requests/domain/help_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('caregiver Home shows household help request and handles it', (
    tester,
  ) async {
    final source = _ShellHelpRequestDataSource();

    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverShell(
          repository: const MockCaregiverRepository(),
          helpRequestDataSource: source,
          patientPollingInterval: Duration.zero,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('home-help-requests')), findsOneWidget);
    expect(find.text('Nana'), findsOneWidget);
    expect(find.text('Please call me'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('acknowledge-help-request')),
    );
    await tester.pump();
    await tester.pump();

    expect(source.acknowledgeCalls, ['request']);
    expect(find.textContaining('Acknowledged'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('resolve-help-request')),
    );
    await tester.pump();
    await tester.pump();

    expect(source.resolveCalls, ['request']);
    expect(find.byKey(const Key('home-help-requests-empty')), findsOneWidget);
  });

  testWidgets('caregiver Home polling refreshes help requests', (tester) async {
    final source = _ShellHelpRequestDataSource();

    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverShell(
          repository: const MockCaregiverRepository(),
          helpRequestDataSource: source,
          patientPollingInterval: const Duration(milliseconds: 100),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final fetchesBeforePoll = source.fetchCalls;

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(source.fetchCalls, greaterThan(fetchesBeforePoll));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _ShellHelpRequestDataSource implements CaregiverHelpRequestDataSource {
  final List<String> acknowledgeCalls = [];
  final List<String> resolveCalls = [];
  int fetchCalls = 0;

  HelpRequestRecord current = _record();

  @override
  Future<HelpRequestPage> fetchRequests({
    List<HelpRequestStatus> statuses = const [],
    String? patientId,
    int limit = 100,
    int offset = 0,
  }) async {
    fetchCalls++;

    return HelpRequestPage(
      items: current.status == HelpRequestStatus.resolved
          ? const []
          : [current],
      total: current.status == HelpRequestStatus.resolved ? 0 : 1,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<HelpRequestRecord> fetchRequest(String helpRequestId) async {
    return current;
  }

  @override
  Future<HelpRequestRecord> acknowledge(String helpRequestId) async {
    acknowledgeCalls.add(helpRequestId);
    current = _record(status: HelpRequestStatus.acknowledged);
    return current;
  }

  @override
  Future<HelpRequestRecord> resolve(String helpRequestId) async {
    resolveCalls.add(helpRequestId);
    current = _record(status: HelpRequestStatus.resolved);
    return current;
  }
}

HelpRequestRecord _record({
  HelpRequestStatus status = HelpRequestStatus.pending,
}) {
  final requested = DateTime(2026, 10, 5, 10);

  return HelpRequestRecord(
    id: 'request',
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
