import 'package:alera/features/elderly/data/api/elderly_help_request_api_service.dart';
import 'package:alera/features/elderly/data/elderly_help_request_controller.dart';
import 'package:alera/features/elderly/domain/models/elderly_help_request.dart';
import 'package:alera/interfaces/elderly_interface.dart';
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

    await tester.tap(find.byKey(const Key('elderly-sign-out')));
    await tester.pump();

    expect(signedOut, isTrue);
  });
}

class _FakeHelpRequestDataSource implements ElderlyHelpRequestDataSource {
  int createCalls = 0;

  @override
  String createActionId() => 'action-id';

  @override
  Future<ElderlyHelpRequest?> fetchActive() async => null;

  @override
  Future<ElderlyHelpRequest> create({
    required String clientActionId,
    String? message,
  }) async {
    createCalls++;

    return ElderlyHelpRequest(
      id: 'help-request-id',
      patientId: 'patient-id',
      status: ElderlyHelpRequestStatus.pending,
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
