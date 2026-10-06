import 'package:flutter/foundation.dart';

import '../../../help_requests/domain/help_request.dart';
import '../api/caregiver_help_request_api_data_source.dart';
import 'caregiver_help_request_note.dart';

enum HelpRequestDetailState { initialLoading, success, error }

class CaregiverHelpRequestDetailController extends ChangeNotifier {
  CaregiverHelpRequestDetailController({
    required this.helpRequestId,
    required this.dataSource,
    required this.notesDataSource,
  });

  final String helpRequestId;
  final CaregiverHelpRequestDataSource dataSource;
  final CaregiverHelpRequestNotesDataSource notesDataSource;

  HelpRequestDetailState _state = HelpRequestDetailState.initialLoading;
  HelpRequestRecord? _request;
  List<HelpRequestNoteRecord> _notes = const [];
  String? _errorMessage;
  String? _noteErrorMessage;
  bool _addingNote = false;
  String? _pendingActionId;
  String? _pendingNote;
  bool _disposed = false;
  int _revision = 0;

  HelpRequestDetailState get state => _state;
  HelpRequestRecord? get request => _request;
  List<HelpRequestNoteRecord> get notes => List.unmodifiable(_notes);
  String? get errorMessage => _errorMessage;
  String? get noteErrorMessage => _noteErrorMessage;
  bool get addingNote => _addingNote;
  bool get canRetryNote =>
      !_addingNote && _pendingActionId != null && _pendingNote != null;

  Future<void> load() async {
    if (_disposed) return;

    final revision = ++_revision;
    _state = HelpRequestDetailState.initialLoading;
    _errorMessage = null;
    _notify();

    try {
      final results = await Future.wait<Object>([
        dataSource.fetchRequest(helpRequestId),
        notesDataSource.fetchNotes(helpRequestId),
      ]);

      if (_disposed || revision != _revision) return;

      final request = results[0] as HelpRequestRecord;
      final notePage = results[1] as HelpRequestNotePage;

      _request = request;
      _notes = List.unmodifiable(_sortedNotes(notePage.items));
      _state = HelpRequestDetailState.success;
    } on CaregiverHelpRequestFailure catch (error) {
      if (_disposed || revision != _revision) return;

      _errorMessage = error.message;
      _state = HelpRequestDetailState.error;
    } catch (_) {
      if (_disposed || revision != _revision) return;

      _errorMessage = 'Unable to load this help request. Please retry.';
      _state = HelpRequestDetailState.error;
    } finally {
      if (!_disposed && revision == _revision) _notify();
    }
  }

  Future<bool> addNote(String value) async {
    final note = value.trim();

    if (_disposed || _addingNote || note.isEmpty) return false;

    if (_pendingNote != note || _pendingActionId == null) {
      _pendingNote = note;
      _pendingActionId = notesDataSource.createNoteActionId();
    }

    final actionId = _pendingActionId!;

    _addingNote = true;
    _noteErrorMessage = null;
    _notify();

    try {
      final created = await notesDataSource.addNote(
        helpRequestId,
        clientActionId: actionId,
        note: note,
      );

      if (_disposed) return false;

      final byId = <String, HelpRequestNoteRecord>{
        for (final item in _notes) item.id: item,
        created.id: created,
      };

      _notes = List.unmodifiable(_sortedNotes(byId.values));
      _pendingActionId = null;
      _pendingNote = null;
      return true;
    } on CaregiverHelpRequestFailure catch (error) {
      if (_disposed) return false;

      _noteErrorMessage = error.message;
      return false;
    } catch (_) {
      if (_disposed) return false;

      _noteErrorMessage = 'Unable to add this note. Please try again.';
      return false;
    } finally {
      if (!_disposed) {
        _addingNote = false;
        _notify();
      }
    }
  }

  Future<bool> retryNote() {
    final note = _pendingNote;
    if (note == null) return Future<bool>.value(false);
    return addNote(note);
  }

  static List<HelpRequestNoteRecord> _sortedNotes(
    Iterable<HelpRequestNoteRecord> notes,
  ) {
    return notes.toList()..sort((a, b) {
      final createdOrder = a.createdAt.compareTo(b.createdAt);
      if (createdOrder != 0) return createdOrder;
      return a.id.compareTo(b.id);
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    super.dispose();
  }
}
