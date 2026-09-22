import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:alera/features/caregiver/presentation/people/caregiver_people_page.dart';
import 'package:alera/features/caregiver/presentation/people/widgets/care_recipient_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MockCaregiverRepository repository = MockCaregiverRepository();

  testWidgets('renders mock recipients and reference hierarchy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaregiverPeoplePage(
            careRecipients: repository.getCareRecipients(),
            onCareRecipientSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('People'), findsOneWidget);
    expect(find.text('Maria Santos'), findsOneWidget);
    expect(find.text('Geraldine Laggui'), findsOneWidget);
    // Was 'High Heart Rate': an arbitrary placeholder for any non-stable
    // status that had no real tie to Maria's CareStatus.needsAttention.
    // PatientStatusChip renders the actual status instead.
    expect(find.text('Attention needed'), findsOneWidget);
    expect(find.text('Stable'), findsOneWidget);
    expect(find.text('2 Alerts'), findsOneWidget);
    expect(find.text('No Alerts'), findsOneWidget);
    expect(find.text('Add Patient'), findsOneWidget);
    expect(find.byTooltip('Filter people'), findsOneWidget);
    expect(find.byTooltip('Edit people'), findsOneWidget);

    final Size cardSize = tester.getSize(find.byType(CareRecipientCard).first);
    expect(cardSize.width, 768);
    // Widened from 120: the status row is now an AleraStatusChip pill with
    // its own vertical padding, a few px taller than the old plain icon+text
    // row it replaced. Confirm the real number with `flutter test` and
    // tighten this back up.
    expect(cardSize.height, inInclusiveRange(112, 132));
  });

  testWidgets('header and Add Patient actions show mock-only feedback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaregiverPeoplePage(
            careRecipients: repository.getCareRecipients(),
            onCareRecipientSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Filter people'));
    await tester.pump();
    expect(find.textContaining('not available in the mock'), findsOneWidget);

    await tester.tap(find.text('Add Patient'));
    await tester.pump();
    expect(
      find.text('Adding a patient is not available in the mock yet.'),
      findsOneWidget,
    );
  });
}
