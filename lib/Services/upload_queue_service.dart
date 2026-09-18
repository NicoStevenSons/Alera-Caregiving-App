import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/alera_database.dart';

class UploadQueueService {
  final AleraDatabase _aleraDatabase = AleraDatabase.instance;

  Future<int> enqueue({
    required String metricType,
    required Map<String, dynamic> payload,
    String queueStatus = 'PENDING',
    String? lastError,
  }) async {
    final Database db = await _aleraDatabase.database;

    return db.insert('upload_queue', {
      'metric_type': metricType,
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'retry_count': 0,
      'queue_status': queueStatus,
      'last_error': lastError,
    });
  }

  Future<Map<String, dynamic>?> getOldestPending() async {
    final Database db = await _aleraDatabase.database;

    final List<Map<String, dynamic>> rows = await db.query(
      'upload_queue',
      where: 'queue_status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'id ASC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllPending() async {
    final Database db = await _aleraDatabase.database;

    return db.query(
      'upload_queue',
      where: 'queue_status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'id ASC',
    );
  }

  Future<void> deleteById(int id) async {
    final Database db = await _aleraDatabase.database;

    await db.delete('upload_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateFailure({
    required int id,
    required int retryCount,
    required String error,
  }) async {
    final Database db = await _aleraDatabase.database;

    await db.update(
      'upload_queue',
      {'retry_count': retryCount, 'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearPendingQueue() async {
    final Database db = await _aleraDatabase.database;

    return db.delete(
      'upload_queue',
      where: 'queue_status = ?',
      whereArgs: ['PENDING'],
    );
  }

  Future<void> updateTemporaryFailure({
    required int id,
    required String error,
  }) async {
    final Database db = await _aleraDatabase.database;

    await db.update(
      'upload_queue',
      {'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> moveToDeadLetter({
    required int id,
    required int retryCount,
    required String error,
  }) async {
    final Database db = await _aleraDatabase.database;

    await db.update(
      'upload_queue',
      {
        'retry_count': retryCount,
        'queue_status': 'DEAD_LETTER',
        'last_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearPendingQueueByMetric(String metricType) async {
    final Database db = await _aleraDatabase.database;

    return db.delete(
      'upload_queue',
      where: 'queue_status = ? AND metric_type = ?',
      whereArgs: ['PENDING', metricType],
    );
  }
}
