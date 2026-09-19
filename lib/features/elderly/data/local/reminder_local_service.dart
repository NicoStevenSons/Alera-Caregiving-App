import 'package:sqflite/sqflite.dart';
import '../../../../database/alera_database.dart';
import '../../domain/models/elderly_reminder.dart';

class ReminderLocalService {
  Future<void> saveReminders(List<ElderlyReminder> reminders) async {
    final db = await AleraDatabase.instance.database;

    final batch = db.batch();

    for (final reminder in reminders) {
      batch.insert('reminder_cache', {
        'occurrence_id': reminder.occurrenceId,
        'template_id': reminder.templateId,
        'patient_id': reminder.patientId,
        'title': reminder.title,
        'instructions': reminder.instructions,
        'category': reminder.category,
        'priority': reminder.priority,
        'scheduled_at': reminder.scheduledAt.toIso8601String(),
        'due_at': reminder.dueAt.toIso8601String(),
        'status': reminder.status,
        'snooze_allowed': reminder.snoozeAllowed ? 1 : 0,
        'default_snooze_minutes': reminder.defaultSnoozeMinutes,
        'synced_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<ElderlyReminder>> getReminders(String patientId) async {
    final db = await AleraDatabase.instance.database;

    final rows = await db.query(
      'reminder_cache',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'due_at ASC',
    );

    return rows.map((row) {
      return ElderlyReminder(
        occurrenceId: row['occurrence_id'] as String,
        templateId: row['template_id'] as String,
        patientId: row['patient_id'] as String,
        title: row['title'] as String,
        instructions: row['instructions'] as String?,
        category: row['category'] as String,
        priority: row['priority'] as String,
        scheduledAt: DateTime.parse(row['scheduled_at'] as String),
        dueAt: DateTime.parse(row['due_at'] as String),
        status: row['status'] as String,
        snoozeAllowed: (row['snooze_allowed'] as int) == 1,
        defaultSnoozeMinutes: row['default_snooze_minutes'] as int,
      );
    }).toList();
  }

  Future<void> completeReminder(ElderlyReminder reminder) async {
    final db = await AleraDatabase.instance.database;

    final bool isLate = DateTime.now().isAfter(reminder.dueAt);

    final String newStatus = isLate ? 'COMPLETED_LATE' : 'COMPLETED';

    await db.transaction((txn) async {
      await txn.update(
        'reminder_cache',
        {'status': newStatus},
        where: 'occurrence_id = ?',
        whereArgs: [reminder.occurrenceId],
      );

      await txn.insert('reminder_action_queue', {
        'occurrence_id': reminder.occurrenceId,
        'action_type': 'MARK_COMPLETED',
        'previous_status': reminder.status,
        'new_status': newStatus,
        'new_due_at': null,
        'action_note': null,
        'created_at': DateTime.now().toIso8601String(),
        'queue_status': 'PENDING',
        'retry_count': 0,
        'last_error': null,
      });
    });
  }

  Future<DateTime> snoozeReminder(ElderlyReminder reminder) async {
    final db = await AleraDatabase.instance.database;

    final DateTime newDueAt = DateTime.now().add(
      Duration(minutes: reminder.defaultSnoozeMinutes),
    );

    await db.transaction((txn) async {
      await txn.update(
        'reminder_cache',
        {'status': 'SNOOZED', 'due_at': newDueAt.toIso8601String()},
        where: 'occurrence_id = ?',
        whereArgs: [reminder.occurrenceId],
      );

      await txn.insert('reminder_action_queue', {
        'occurrence_id': reminder.occurrenceId,
        'action_type': 'SNOOZE',
        'previous_status': reminder.status,
        'new_status': 'SNOOZED',
        'new_due_at': newDueAt.toIso8601String(),
        'action_note': null,
        'created_at': DateTime.now().toIso8601String(),
        'queue_status': 'PENDING',
        'retry_count': 0,
        'last_error': null,
      });
    });

    return newDueAt;
  }

  Future<ElderlyReminder?> getReminder(String occurrenceId) async {
    final db = await AleraDatabase.instance.database;

    final rows = await db.query(
      'reminder_cache',
      where: 'occurrence_id = ?',
      whereArgs: [occurrenceId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;

    return ElderlyReminder(
      occurrenceId: row['occurrence_id'] as String,
      templateId: row['template_id'] as String,
      patientId: row['patient_id'] as String,
      title: row['title'] as String,
      instructions: row['instructions'] as String?,
      category: row['category'] as String,
      priority: row['priority'] as String,
      scheduledAt: DateTime.parse(row['scheduled_at'] as String),
      dueAt: DateTime.parse(row['due_at'] as String),
      status: row['status'] as String,
      snoozeAllowed: (row['snooze_allowed'] as int) == 1,
      defaultSnoozeMinutes: row['default_snooze_minutes'] as int,
    );
  }

  Future<List<Map<String, Object?>>> getPendingReminderActions() async {
    final db = await AleraDatabase.instance.database;

    return db.query(
      'reminder_action_queue',
      where: 'queue_status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'id ASC',
    );
  }

  Future<void> deleteReminderAction(int id) async {
    final db = await AleraDatabase.instance.database;

    await db.delete('reminder_action_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markReminderActionFailed(int id, String error) async {
    final db = await AleraDatabase.instance.database;

    await db.rawUpdate(
      '''
    UPDATE reminder_action_queue
    SET retry_count = retry_count + 1,
        last_error = ?
    WHERE id = ?
    ''',
      [error, id],
    );
  }
}
