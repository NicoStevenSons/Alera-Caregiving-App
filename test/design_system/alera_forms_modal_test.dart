import 'dart:async';

import 'package:alera/design_system/widgets/alera_bottom_sheet.dart';
import 'package:alera/design_system/widgets/alera_form_section.dart';
import 'package:alera/design_system/widgets/alera_text_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('text dialog validates and returns trimmed input', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAleraTextInputDialog(
                  context: context,
                  title: 'Cancel occurrence',
                  fieldLabel: 'Reason',
                  submitLabel: 'Cancel reminder',
                  fieldKey: const Key('reason-field'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel reminder'));
    await tester.pump();
    expect(find.text('Reason is required.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('reason-field')), '  Done  ');
    await tester.tap(find.text('Cancel reminder'));
    await tester.pumpAndSettle();
    expect(result, 'Done');
  });

  testWidgets('async text dialog disables actions and reports failure', (
    tester,
  ) async {
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAleraAsyncTextInputDialog(
                context: context,
                title: 'Resolve',
                fieldLabel: 'Resolution',
                submitLabel: 'Resolve',
                failureMessage: 'Unable to resolve.',
                onSubmit: (_) => pending.future,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Patient is stable.');
    await tester.tap(find.text('Resolve').last);
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);

    pending.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to resolve.'), findsOneWidget);
    expect(find.text('Resolve'), findsWidgets);
  });

  testWidgets('bottom sheet shell and form section share structure', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAleraBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AleraBottomSheetShell(
                  title: 'Create reminder',
                  child: SingleChildScrollView(
                    child: AleraFormSection(
                      title: 'Schedule',
                      description: 'Choose when this reminder should occur.',
                      children: [TextField()],
                    ),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Create reminder'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Schedule'), findsNothing);
  });

  testWidgets('canceling a text dialog disposes its owned controller safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAleraTextInputDialog(
                context: context,
                title: 'Add note',
                fieldLabel: 'Note',
                submitLabel: 'Save',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Temporary note');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
