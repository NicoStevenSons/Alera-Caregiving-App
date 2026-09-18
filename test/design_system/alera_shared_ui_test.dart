import 'package:alera/design_system/widgets/alera_async_view.dart';
import 'package:alera/design_system/widgets/alera_dialog.dart';
import 'package:alera/design_system/widgets/alera_feedback.dart';
import 'package:alera/design_system/widgets/alera_page_app_bar.dart';
import 'package:alera/design_system/widgets/alera_patient_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('async views expose their state and actions', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AleraErrorView(
            message: 'Unable to load patients.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Unable to load patients.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AleraEmptyView(
            title: 'No reminders yet',
            message: 'Create a schedule to get started.',
          ),
        ),
      ),
    );
    expect(find.text('No reminders yet'), findsOneWidget);
  });

  testWidgets('confirmation dialog returns the selected result', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showAleraConfirmDialog(
                context: context,
                title: 'Archive schedule?',
                message: 'Future occurrences will be canceled.',
                confirmLabel: 'Archive',
                destructive: true,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(AleraDialog), findsOneWidget);
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('feedback replaces the current message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => AleraFeedback.success(context, 'Saved.'),
            child: const Text('Save'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Saved.'), findsOneWidget);
  });

  testWidgets('page app bar supports leading navigation and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AleraPageAppBar(
            title: 'Reminders',
            actions: [
              aleraPageAction(
                tooltip: 'Add reminder',
                onPressed: () {},
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Reminders'), findsOneWidget);
    expect(find.byTooltip('Add reminder'), findsOneWidget);
  });

  testWidgets('patient avatar derives stable initials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AleraPatientAvatar(name: 'Alera Test Patient')),
      ),
    );

    expect(find.text('AT'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
  });
}
