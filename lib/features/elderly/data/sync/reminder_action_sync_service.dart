import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/reminder_local_service.dart';

class ReminderActionSyncService {
  final ReminderLocalService localService;

  ReminderActionSyncService({required this.localService});

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> syncPendingActions({required String performedByUserId}) async {
    final actions = await localService.getPendingReminderActions();

    debugPrint('Found ${actions.length} pending reminder actions');

    for (final action in actions) {
      final int localId = action['id'] as int;

      try {
        await _syncOneAction(action, performedByUserId);

        await localService.deleteReminderAction(localId);

        debugPrint('Synced reminder action $localId');
      } catch (error) {
        await localService.markReminderActionFailed(localId, error.toString());

        debugPrint(
          'Failed to sync reminder action '
          '$localId: $error',
        );

        break;
      }
    }
  }

  Future<void> _syncOneAction(
    Map<String, Object?> action,
    String performedByUserId,
  ) async {
    final String occurrenceId = action['occurrence_id'] as String;

    final String actionType = action['action_type'] as String;

    final String? previousStatus = action['previous_status'] as String?;

    final String? newStatus = action['new_status'] as String?;

    final String? newDueAt = action['new_due_at'] as String?;

    final String? actionNote = action['action_note'] as String?;

    //Update current occurrence state
    final occurrenceUpdate = <String, dynamic>{};

    if (newStatus != null) {
      occurrenceUpdate['status'] = newStatus;
    }

    if (newDueAt != null) {
      occurrenceUpdate['due_at'] = newDueAt;
    }

    occurrenceUpdate['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await _supabase
        .from('reminder_occurrences')
        .update(occurrenceUpdate)
        .eq('reminder_occurrence_id', occurrenceId);

    //Write audit/history action
    await _supabase.from('reminder_actions').insert({
      'reminder_occurrence_id': occurrenceId,
      'performed_by_user_id': performedByUserId,
      'action_type': actionType,
      'action_note': actionNote,
      'previous_status': previousStatus,
      'new_status': newStatus,
      'new_due_at': newDueAt,
      'metadata': <String, dynamic>{},
      'performed_at': action['created_at'],
    });
  }
}
