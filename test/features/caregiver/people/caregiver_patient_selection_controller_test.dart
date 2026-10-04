import 'dart:async';

import 'package:alera/features/caregiver/data/patients/caregiver_patient_selection_controller.dart';
import 'package:alera/features/caregiver/data/patients/caregiver_patient_selection_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores an accessible saved patient', () async {
    final store = _Store()..values['caregiver'] = 'b';
    final controller = _controller(store);
    await controller.restore();
    controller.reconcile(['a', 'b']);
    expect(controller.selectedPatientId, 'b');
  });

  test(
    'does not reconcile before the saved preference finishes loading',
    () async {
      final store = _Store()..pendingRead = Completer<String?>();
      final controller = _controller(store);
      final restoring = controller.restore();

      expect(controller.reconcile(['a', 'b']), isFalse);
      expect(controller.selectedPatientId, isNull);

      store.pendingRead!.complete('b');
      await restoring;
      controller.reconcile(['a', 'b']);
      expect(controller.selectedPatientId, 'b');
    },
  );

  test('fresh selection wins over a delayed restore', () async {
    final store = _Store()..pendingRead = Completer<String?>();
    final controller = _controller(store);
    final restoring = controller.restore();

    controller.select('a', ['a', 'b']);
    store.pendingRead!.complete('b');
    await restoring;
    controller.reconcile(['a', 'b']);
    expect(controller.selectedPatientId, 'a');
  });

  test(
    'removed patient falls back and an empty list clears selection',
    () async {
      final store = _Store()..values['caregiver'] = 'removed';
      final controller = _controller(store);
      await controller.restore();

      controller.reconcile(['a']);
      expect(controller.selectedPatientId, 'a');
      await _flush();
      expect(store.values['caregiver'], 'a');

      controller.reconcile([]);
      expect(controller.selectedPatientId, isNull);
      await _flush();
      expect(store.values.containsKey('caregiver'), isFalse);
    },
  );

  test('caregiver preferences remain separate', () async {
    final store = _Store()
      ..values['first'] = 'a'
      ..values['second'] = 'b';
    final first = _controller(store, scope: 'first');
    final second = _controller(store, scope: 'second');
    await first.restore();
    await second.restore();
    first.reconcile(['a', 'b']);
    second.reconcile(['a', 'b']);

    expect(first.selectedPatientId, 'a');
    expect(second.selectedPatientId, 'b');
  });

  test(
    'rapid switches save in order even when the first write is slow',
    () async {
      final store = _Store()..firstWriteGate = Completer<void>();
      final controller = _controller(store);
      await controller.restore();

      controller.select('a', ['a', 'b']);
      await _flush();
      controller.select('b', ['a', 'b']);
      await _flush();
      expect(store.writes, ['a']);

      store.firstWriteGate!.complete();
      await _flush();
      expect(store.writes, ['a', 'b']);
      expect(store.values['caregiver'], 'b');
      expect(controller.selectedPatientId, 'b');
    },
  );

  test('rejects a patient outside the accessible list', () async {
    final store = _Store();
    final controller = _controller(store);
    await controller.restore();
    controller.reconcile(['a']);
    expect(controller.select('other', ['a']), isFalse);
    expect(controller.selectedPatientId, 'a');
  });
}

CaregiverPatientSelectionController _controller(
  _Store store, {
  String scope = 'caregiver',
}) => CaregiverPatientSelectionController(store: store, caregiverId: scope);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _Store implements CaregiverPatientSelectionStore {
  final values = <String, String>{};
  final writes = <String>[];
  Completer<String?>? pendingRead;
  Completer<void>? firstWriteGate;

  @override
  Future<String?> read(String caregiverId) async =>
      pendingRead == null ? values[caregiverId] : await pendingRead!.future;

  @override
  Future<void> write(String caregiverId, String patientId) async {
    writes.add(patientId);
    if (writes.length == 1 && firstWriteGate != null) {
      await firstWriteGate!.future;
    }
    values[caregiverId] = patientId;
  }

  @override
  Future<void> clear(String caregiverId) async {
    values.remove(caregiverId);
  }
}
