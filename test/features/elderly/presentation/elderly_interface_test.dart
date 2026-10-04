import 'package:alera/interfaces/elderly_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('patient shell navigates between Home, Reminders, and More', (
    tester,
  ) async {
    var signedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ElderlyInterface(
          patientId: 'a076ecdb-ae38-4f84-b490-e714977027ee',
          onSignOut: () => signedOut = true,
        ),
      ),
    );
    await tester.pump();

    NavigationBar navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 0);
    expect(find.byKey(const Key('elderly-request-help')), findsOneWidget);

    final helpButton = tester.widget<FilledButton>(
      find.byKey(const Key('elderly-request-help')),
    );
    expect(helpButton.onPressed, isNull);

    await tester.tap(find.text('Reminders'));
    await tester.pump();

    navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 1);

    await tester.tap(find.text('More'));
    await tester.pump();

    navigation = tester.widget(find.byType(NavigationBar));
    expect(navigation.selectedIndex, 2);
    expect(find.byKey(const Key('elderly-sign-out')), findsOneWidget);

    await tester.tap(find.byKey(const Key('elderly-sign-out')));
    await tester.pump();

    expect(signedOut, isTrue);
  });
}
