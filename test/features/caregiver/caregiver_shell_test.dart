import 'package:alera/features/caregiver/caregiver_shell.dart';
import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows five destinations and switches retained pages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverShell(repository: MockCaregiverRepository()),
      ),
    );

    expect(find.byType(IndexedStack), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('Maria Santos'), findsOneWidget);

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('Geraldine Laggui'), findsOneWidget);

    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Reminders').first, findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Temporary More placeholder'), findsOneWidget);

    final IndexedStack stack = tester.widget(find.byType(IndexedStack));
    expect(stack.children, hasLength(5));
  });

  testWidgets('selecting a patient pushes detail and retains People page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CaregiverShell(repository: MockCaregiverRepository()),
      ),
    );

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();

    final Finder peoplePage = find.byKey(
      const PageStorageKey<String>('caregiver-people-list'),
      skipOffstage: false,
    );
    expect(peoplePage, findsOneWidget);

    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('caregiver-patient-detail-maria-santos')),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(peoplePage, findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    final NavigationBar navigationBar = tester.widget(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 1);
    expect(peoplePage, findsOneWidget);
  });
}
