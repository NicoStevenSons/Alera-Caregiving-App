import 'package:alera/features/caregiver/data/api/caregiver_help_request_api_data_source.dart';
import 'package:alera/features/caregiver/data/help_requests/caregiver_help_request_note.dart';
import 'package:alera/features/caregiver/presentation/more/caregiver_more_page.dart';
import 'package:alera/features/help_requests/domain/help_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'More opens history, detail, lifecycle, and adds a private note',
    (tester) async {
      final source = _HistorySource();

      await tester.pumpWidget(
        MaterialApp(
          home: CaregiverMorePage(
            helpRequestDataSource: source,
            onManagePatients: () {},
            onAddPatient: () {},
          ),
        ),
      );

      expect(
        find.byKey(const Key('more-help-request-history')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('more-help-request-history')));
      await tester.pumpAndSettle();

      expect(find.text('Help request history'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('help-history-request-active-request'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Please call me'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('help-history-request-active-request'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help-request-detail')), findsOneWidget);
      expect(find.text('Lifecycle'), findsOneWidget);
      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('Acknowledged'), findsNWidgets(2));
      expect(find.text('Private to assigned caregivers.'), findsOneWidget);
      expect(find.text('Initial caregiver note.'), findsOneWidget);

      final detailList = find.byKey(const Key('help-request-detail'));
      final detailScrollable = find
          .descendant(of: detailList, matching: find.byType(Scrollable))
          .first;
      final noteInput = find.byKey(const Key('help-request-note-input'));
      final addNoteButton = find.byKey(const Key('add-help-request-note'));

      await tester.scrollUntilVisible(
        noteInput,
        250,
        scrollable: detailScrollable,
      );
      await tester.enterText(noteInput, '  Family is on the way.  ');
      await tester.scrollUntilVisible(
        addNoteButton,
        150,
        scrollable: detailScrollable,
      );
      await tester.tap(addNoteButton);
      await tester.pumpAndSettle();

      expect(source.submittedActionIds, ['generated-note-action-1']);
      expect(source.submittedNotes, ['Family is on the way.']);
      expect(find.text('Family is on the way.'), findsOneWidget);
      expect(find.text('Caregiver note added.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('help-request-note-input')))
            .controller
            ?.text,
        isEmpty,
      );
    },
  );

  testWidgets('history switches from active to resolved requests', (
    tester,
  ) async {
    final source = _HistorySource();

    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverMorePage(
          helpRequestDataSource: source,
          onManagePatients: () {},
          onAddPatient: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('more-help-request-history')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('help-history-request-active-request')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('help-history-request-resolved-request'),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('help-history-resolved-filter')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('help-history-request-active-request')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey<String>('help-history-request-resolved-request'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('More disables history without a notes-capable source', (
    tester,
  ) async {
    var signedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverMorePage(
          helpRequestDataSource: null,
          onManagePatients: () {},
          onAddPatient: () {},
          onSignOut: () => signedOut = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('more-help-request-history')));
    await tester.pump();
    expect(find.text('Help request history is coming soon.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));

    await tester.ensureVisible(find.byKey(const Key('caregiver-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('caregiver-sign-out')));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
  });
}

class _HistorySource
    implements
        CaregiverHelpRequestDataSource,
        CaregiverHelpRequestNotesDataSource {
  final List<HelpRequestRecord> records = [
    _request(id: 'active-request', status: HelpRequestStatus.acknowledged),
    _request(id: 'resolved-request', status: HelpRequestStatus.resolved),
  ];

  final List<HelpRequestNoteRecord> notes = [
    _note(
      id: 'initial-note',
      actionId: 'initial-action',
      value: 'Initial caregiver note.',
    ),
  ];

  int generatedIds = 0;
  final List<String> submittedActionIds = [];
  final List<String> submittedNotes = [];

  @override
  Future<HelpRequestPage> fetchRequests({
    List<HelpRequestStatus> statuses = const [],
    String? patientId,
    int limit = 100,
    int offset = 0,
  }) async {
    final matching = records
        .where((record) => statuses.contains(record.status))
        .toList();

    return HelpRequestPage(
      items: matching,
      total: matching.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<HelpRequestRecord> fetchRequest(String helpRequestId) async {
    return records.firstWhere((record) => record.id == helpRequestId);
  }

  @override
  Future<HelpRequestRecord> acknowledge(String helpRequestId) async {
    return fetchRequest(helpRequestId);
  }

  @override
  Future<HelpRequestRecord> resolve(String helpRequestId) async {
    return fetchRequest(helpRequestId);
  }

  @override
  String createNoteActionId() {
    generatedIds++;
    return 'generated-note-action-$generatedIds';
  }

  @override
  Future<HelpRequestNotePage> fetchNotes(
    String helpRequestId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final matching = helpRequestId == 'active-request'
        ? List<HelpRequestNoteRecord>.of(notes)
        : <HelpRequestNoteRecord>[];

    return HelpRequestNotePage(
      items: matching,
      total: matching.length,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<HelpRequestNoteRecord> addNote(
    String helpRequestId, {
    required String clientActionId,
    required String note,
  }) async {
    submittedActionIds.add(clientActionId);
    submittedNotes.add(note);

    final created = _note(
      id: 'created-note',
      actionId: clientActionId,
      value: note,
    );
    notes.add(created);
    return created;
  }
}

HelpRequestRecord _request({
  required String id,
  required HelpRequestStatus status,
}) {
  final requestedAt = DateTime.utc(2026, 10, 6, 9);

  return HelpRequestRecord(
    id: id,
    patientId: 'patient-id',
    status: status,
    message: 'Please call me',
    clientActionId: 'request-action-$id',
    requestedAt: requestedAt,
    acknowledgedByUserId: status == HelpRequestStatus.acknowledged
        ? 'caregiver-id'
        : null,
    acknowledgedAt: status == HelpRequestStatus.acknowledged
        ? requestedAt.add(const Duration(minutes: 1))
        : null,
    resolvedByUserId: status == HelpRequestStatus.resolved
        ? 'caregiver-id'
        : null,
    resolvedAt: status == HelpRequestStatus.resolved
        ? requestedAt.add(const Duration(minutes: 2))
        : null,
    updatedAt: requestedAt,
    patientDisplayName: 'Nana',
    idempotent: false,
  );
}

HelpRequestNoteRecord _note({
  required String id,
  required String actionId,
  required String value,
}) {
  return HelpRequestNoteRecord(
    id: id,
    helpRequestId: 'active-request',
    authorUserId: 'caregiver-id',
    clientActionId: actionId,
    note: value,
    createdAt: DateTime.utc(2026, 10, 6, 10),
    authorDisplayName: 'Caregiver Ana',
    idempotent: false,
  );
}
