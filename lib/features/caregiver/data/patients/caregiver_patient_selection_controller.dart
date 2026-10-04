import 'caregiver_patient_selection_store.dart';

class CaregiverPatientSelectionController {
  CaregiverPatientSelectionController({
    required this.store,
    required this.caregiverId,
  });

  final CaregiverPatientSelectionStore store;
  final String? caregiverId;

  String? selectedPatientId;
  String? _restoredPatientId;
  bool _restoreComplete = false;
  int _selectionRevision = 0;
  Future<void> _saveQueue = Future<void>.value();

  Future<void> restore() async {
    final revision = _selectionRevision;
    final scope = caregiverId;
    String? saved;
    try {
      if (scope != null) saved = await store.read(scope);
    } catch (_) {
      // Selection still works when local preference storage is unavailable.
    }
    if (revision != _selectionRevision) return;
    _restoredPatientId = saved;
    _restoreComplete = true;
  }

  /// Call only with a successfully loaded, authoritative patient list.
  /// Loading errors and demo fallback must not erase a saved preference.
  bool reconcile(List<String> accessiblePatientIds) {
    if (!_restoreComplete) return false;

    final previous = selectedPatientId;
    final preferred = selectedPatientId ?? _restoredPatientId;
    final hadSavedPreference = _restoredPatientId != null;

    selectedPatientId =
        preferred != null && accessiblePatientIds.contains(preferred)
        ? preferred
        : accessiblePatientIds.isEmpty
        ? null
        : accessiblePatientIds.first;
    _restoredPatientId = null;

    if (previous != selectedPatientId || hadSavedPreference) {
      _persist(selectedPatientId);
    }
    return previous != selectedPatientId;
  }

  bool select(String patientId, List<String> accessiblePatientIds) {
    if (!accessiblePatientIds.contains(patientId)) return false;

    ++_selectionRevision;
    _restoreComplete = true;
    _restoredPatientId = null;
    if (selectedPatientId == patientId) return false;

    selectedPatientId = patientId;
    _persist(patientId);
    return true;
  }

  void _persist(String? patientId) {
    final scope = caregiverId;
    if (scope == null) return;

    // Serialize writes so an earlier tap cannot finish after a later tap.
    _saveQueue = _saveQueue.then((_) async {
      try {
        if (patientId == null) {
          await store.clear(scope);
        } else {
          await store.write(scope, patientId);
        }
      } catch (_) {
        // A storage failure must not prevent switching patients.
      }
    });
  }
}
