import 'package:alera/features/elderly/data/api/elderly_help_request_api_service.dart';
import 'package:alera/features/elderly/data/elderly_help_request_controller.dart';
import 'package:alera/features/help_requests/domain/help_request.dart';
import 'package:alera/interfaces/elderly_interface.dart';
import 'package:alera/services/help_request_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('patient shell handles help and navigation', (tester) async {
    var signedOut = false;
    final helpSource = _FakeHelpRequestDataSource();
    final helpController = ElderlyHelpRequestController(dataSource: helpSource);

    await helpController.load();
    addTearDown(helpController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ElderlyInterface(
          patientId: 'a076ecdb-ae38-4f84-b490-e714977027ee',
          onSignOut: () => signedOut = true,
          helpRequestController: helpController,
        ),
      ),
    );
    await tester.pump();

    NavigationBar navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 0);

    final helpButton = tester.widget<FilledButton>(
      find.byKey(const Key('elderly-request-help')),
    );
    expect(helpButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('elderly-request-help')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('elderly-help-confirmation')), findsOneWidget);

    await tester.tap(find.byKey(const Key('elderly-help-cancel')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(helpSource.createCalls, 0);
    expect(find.byKey(const Key('elderly-request-help')), findsOneWidget);

    await tester.tap(find.byKey(const Key('elderly-request-help')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('elderly-help-confirm')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(helpSource.createCalls, 1);
    expect(find.byKey(const Key('elderly-help-active')), findsOneWidget);
    expect(find.text('Help request sent'), findsOneWidget);

    await tester.tap(find.byKey(const Key('elderly-monitoring-status')));
    await tester.pump();

    navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 2);
    expect(find.byKey(const Key('elderly-sign-out')), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pump();

    navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 0);

    await tester.tap(find.text('Reminders'));
    await tester.pump();

    navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 1);

    await tester.tap(find.text('More'));
    await tester.pump();

    navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 2);

    await tester.ensureVisible(find.byKey(const Key('elderly-sign-out')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('elderly-sign-out')));
    await tester.pump();

    expect(signedOut, isTrue);
  });

  testWidgets('patient refreshes help-request status on resume', (
    tester,
  ) async {
    final helpSource = _FakeHelpRequestDataSource();
    final helpController = ElderlyHelpRequestController(dataSource: helpSource);
    addTearDown(helpController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ElderlyInterface(
          patientId: 'a076ecdb-ae38-4f84-b490-e714977027ee',
          helpRequestController: helpController,
        ),
      ),
    );
    await tester.pump();

    final fetchesBeforeResume = helpSource.fetchCalls;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(helpSource.fetchCalls, fetchesBeforeResume + 1);
  });

  testWidgets('acknowledged push refreshes patient help status', (
    tester,
  ) async {
    final helpSource = _FakeHelpRequestDataSource();
    final helpController = ElderlyHelpRequestController(dataSource: helpSource);
    final bus = HelpRequestNotificationBus();
    addTearDown(helpController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ElderlyInterface(
          patientId: 'a076ecdb-ae38-4f84-b490-e714977027ee',
          helpRequestController: helpController,
          helpRequestNotificationBus: bus,
        ),
      ),
    );
    await tester.pump();

    final fetchesBeforePush = helpSource.fetchCalls;

    bus.handle(
      HelpRequestNotification.parse(const {
        'type': 'HELP_REQUEST',
        'event': 'ACKNOWLEDGED',
        'help_request_id': '10000000-0000-4000-8000-000000000001',
        'patient_id': 'a076ecdb-ae38-4f84-b490-e714977027ee',
        'status': 'ACKNOWLEDGED',
        'patient_display_name': 'Test Patient',
      }, messageId: 'patient-acknowledged-message'),
    );
    await tester.pump();

    expect(helpSource.fetchCalls, fetchesBeforePush + 1);
  });
}

class _FakeHelpRequestDataSource implements ElderlyHelpRequestDataSource {
  int createCalls = 0;
  int fetchCalls = 0;

  @override
  String createActionId() => 'action-id';

  @override
  Future<HelpRequestRecord?> fetchActive() async {
    fetchCalls++;
    return null;
  }

  @override
  Future<HelpRequestRecord> create({
    required String clientActionId,
    String? message,
  }) async {
    createCalls++;

    return HelpRequestRecord(
      id: 'help-request-id',
      patientId: 'patient-id',
      status: HelpRequestStatus.pending,
      message: message,
      clientActionId: clientActionId,
      requestedAt: DateTime.utc(2026, 10, 5, 2),
      acknowledgedByUserId: null,
      acknowledgedAt: null,
      resolvedByUserId: null,
      resolvedAt: null,
      updatedAt: DateTime.utc(2026, 10, 5, 2),
      patientDisplayName: 'Test Patient',
      idempotent: false,
    );
  }
}
