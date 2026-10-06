import 'package:alera/features/caregiver/data/api/caregiver_help_request_api_data_source.dart';
import 'package:alera/features/caregiver/data/help_requests/caregiver_help_request_detail_controller.dart';
import 'package:alera/features/caregiver/data/help_requests/caregiver_help_request_history_controller.dart';
import 'package:alera/features/caregiver/data/help_requests/caregiver_help_request_note.dart';
import 'package:alera/features/help_requests/domain/help_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history loads active then resolved requests', () async {
    final source = _FakeHelpRequestSource()
      ..records = [
        _request(
          id: 'pending',
          status: HelpRequestStatus.pending,
          requestedAt: DateTime.utc(2026, 10, 6, 9),
        ),
        _request(
          id: 'acknowledged',
          status: HelpRequestStatus.acknowledged,
          requestedAt: DateTime.utc(2026, 10, 6, 10),
        ),
        _request(
          id: 'resolved',
          status: HelpRequestStatus.resolved,
          requestedAt: DateTime.utc(2026, 10, 6, 11),
        ),
      ];

    final controller = CaregiverHelpRequestHistoryController(
      dataSource: source,
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state, HelpRequestHistoryState.success);
    expect(controller.filter, HelpRequestHistoryFilter.active);
    expect(controller.requests.map((item) => item.id), [
      'acknowledged',
      'pending',
    ]);
    expect(source.requestedStatuses.single, [
      HelpRequestStatus.pending,
      HelpRequestStatus.acknowledged,
    ]);

    await controller.selectFilter(HelpRequestHistoryFilter.resolved);

    expect(controller.state, HelpRequestHistoryState.success);
    expect(controller.filter, HelpRequestHistoryFilter.resolved);
    expect(controller.requests.single.id, 'resolved');
    expect(source.requestedStatuses.last, [HelpRequestStatus.resolved]);
  });

  test('history rejects records outside the selected filter', () async {
    final source = _FakeHelpRequestSource()
      ..ignoreStatusFilter = true
      ..records = [
        _request(id: 'resolved', status: HelpRequestStatus.resolved),
      ];

    final controller = CaregiverHelpRequestHistoryController(
      dataSource: source,
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state, HelpRequestHistoryState.error);
    expect(
      controller.errorMessage,
      'Unable to load help-request history. Please retry.',
    );
  });

  test('detail loads request and chronologically ordered notes', () async {
    final source = _FakeHelpRequestSource()
      ..records = [
        _request(id: 'request-id', status: HelpRequestStatus.acknowledged),
      ];
    final notesSource = _FakeNotesSource()
      ..notes = [
        _note(id: 'later', createdAt: DateTime.utc(2026, 10, 6, 11)),
        _note(id: 'earlier', createdAt: DateTime.utc(2026, 10, 6, 10)),
      ];

    final controller = CaregiverHelpRequestDetailController(
      helpRequestId: 'request-id',
      dataSource: source,
      notesDataSource: notesSource,
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state, HelpRequestDetailState.success);
    expect(controller.request?.id, 'request-id');
    expect(controller.notes.map((item) => item.id), ['earlier', 'later']);
  });

  test('failed note retry reuses its client action id', () async {
    final source = _FakeHelpRequestSource()
      ..records = [
        _request(id: 'request-id', status: HelpRequestStatus.pending),
      ];
    final notesSource = _FakeNotesSource()..failNextAdd = true;

    final controller = CaregiverHelpRequestDetailController(
      helpRequestId: 'request-id',
      dataSource: source,
      notesDataSource: notesSource,
    );
    addTearDown(controller.dispose);

    await controller.load();

    final firstResult = await controller.addNote('  Called Nana.  ');

    expect(firstResult, isFalse);
    expect(controller.canRetryNote, isTrue);
    expect(controller.noteErrorMessage, 'Temporary note failure.');
    expect(notesSource.actionIds, ['generated-action-1']);
    expect(notesSource.submittedNotes, ['Called Nana.']);

    final retryResult = await controller.retryNote();

    expect(retryResult, isTrue);
    expect(controller.canRetryNote, isFalse);
    expect(controller.noteErrorMessage, isNull);
    expect(notesSource.actionIds, ['generated-action-1', 'generated-action-1']);
    expect(controller.notes.single.note, 'Called Nana.');
  });

  test('duplicate note response is deduplicated by note id', () async {
    final source = _FakeHelpRequestSource()
      ..records = [
        _request(id: 'request-id', status: HelpRequestStatus.pending),
      ];
    final existing = _note(
      id: 'same-note',
      clientActionId: 'generated-action-1',
    );
    final notesSource = _FakeNotesSource()
      ..notes = [existing]
      ..createdNoteId = 'same-note';

    final controller = CaregiverHelpRequestDetailController(
      helpRequestId: 'request-id',
      dataSource: source,
      notesDataSource: notesSource,
    );
    addTearDown(controller.dispose);

    await controller.load();
    final result = await controller.addNote('Called Nana.');

    expect(result, isTrue);
    expect(controller.notes, hasLength(1));
    expect(controller.notes.single.id, 'same-note');
  });
}

class _FakeHelpRequestSource implements CaregiverHelpRequestDataSource {
  List<HelpRequestRecord> records = [];
  final List<List<HelpRequestStatus>> requestedStatuses = [];
  bool ignoreStatusFilter = false;

  @override
  Future<HelpRequestPage> fetchRequests({
    List<HelpRequestStatus> statuses = const [],
    String? patientId,
    int limit = 100,
    int offset = 0,
  }) async {
    requestedStatuses.add(List.of(statuses));

    final matching = ignoreStatusFilter
        ? records
        : records.where((record) => statuses.contains(record.status)).toList();

    final end = (offset + limit).clamp(0, matching.length);

    return HelpRequestPage(
      items: offset >= matching.length
          ? const []
          : matching.sublist(offset, end),
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
}

class _FakeNotesSource implements CaregiverHelpRequestNotesDataSource {
  List<HelpRequestNoteRecord> notes = [];
  bool failNextAdd = false;
  String createdNoteId = 'created-note';
  int generatedIds = 0;
  final List<String> actionIds = [];
  final List<String> submittedNotes = [];

  @override
  String createNoteActionId() {
    generatedIds++;
    return 'generated-action-$generatedIds';
  }

  @override
  Future<HelpRequestNotePage> fetchNotes(
    String helpRequestId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return HelpRequestNotePage(
      items: List.of(notes),
      total: notes.length,
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
    actionIds.add(clientActionId);
    submittedNotes.add(note);

    if (failNextAdd) {
      failNextAdd = false;
      throw const CaregiverHelpRequestFailure('Temporary note failure.');
    }

    final created = _note(
      id: createdNoteId,
      clientActionId: clientActionId,
      note: note,
      createdAt: DateTime.utc(2026, 10, 6, 12),
    );
    notes = [...notes, created];
    return created;
  }
}

HelpRequestRecord _request({
  required String id,
  required HelpRequestStatus status,
  DateTime? requestedAt,
}) {
  final requested = requestedAt ?? DateTime.utc(2026, 10, 6, 9);

  return HelpRequestRecord(
    id: id,
    patientId: 'patient-id',
    status: status,
    message: 'Please call me',
    clientActionId: 'request-action-$id',
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

HelpRequestNoteRecord _note({
  required String id,
  String clientActionId = 'note-action',
  String note = 'Called Nana.',
  DateTime? createdAt,
}) {
  return HelpRequestNoteRecord(
    id: id,
    helpRequestId: 'request-id',
    authorUserId: 'caregiver-id',
    clientActionId: clientActionId,
    note: note,
    createdAt: createdAt ?? DateTime.utc(2026, 10, 6, 10),
    authorDisplayName: 'Caregiver Ana',
    idempotent: false,
  );
}
