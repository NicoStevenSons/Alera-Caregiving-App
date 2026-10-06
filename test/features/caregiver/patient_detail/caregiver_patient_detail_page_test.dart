import 'package:alera/features/caregiver/caregiver_shell.dart';
import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows selected patient detail sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverShell(repository: MockCaregiverRepository()),
      ),
    );

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();

    expect(find.text('Maria Santos'), findsOneWidget);

    // Order: header, status, alerts, vitals, reminders, devices.
    await tester.scrollUntilVisible(
      find.text('Needs attention'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('View history'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Vitals'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Vitals'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Reminders'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Reminders'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Devices'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Devices'), findsOneWidget);
  });

  testWidgets('patient selection opens detail and links return to shell tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverShell(repository: MockCaregiverRepository()),
      ),
    );

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Geraldine Laggui'));
    await tester.pumpAndSettle();

    expect(find.text('Geraldine Laggui'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.scrollUntilVisible(
      find.text('View history'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('View history'));
    await tester.pumpAndSettle();

    final NavigationBar navigationBar = tester.widget(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 2);
  });

  testWidgets('contact actions explain when no phone number is saved', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverShell(repository: MockCaregiverRepository()),
      ),
    );

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Call').first);
    await tester.pump();

    expect(
      find.text('No phone number is saved for Maria Santos.'),
      findsOneWidget,
    );
  });
}
