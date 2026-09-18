import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AleraDatabase {
  AleraDatabase._();

  static final AleraDatabase instance = AleraDatabase._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();

    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final String databasePath = await getDatabasesPath();

    final String path = join(databasePath, 'alera_local.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await _createUploadQueue(db);

    await _createReminderCache(db);

    await _createReminderActionQueue(db);
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createReminderCache(db);

      await _createReminderActionQueue(db);
    }
  }

  Future<void> _createUploadQueue(Database db) async {
    await db.execute('''
      CREATE TABLE upload_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        metric_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        queue_status TEXT NOT NULL DEFAULT 'PENDING',
        last_error TEXT
      )
    ''');
  }

  Future<void> _createReminderCache(Database db) async {
    await db.execute('''
      CREATE TABLE reminder_cache (
        occurrence_id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        patient_id TEXT NOT NULL,

        title TEXT NOT NULL,
        instructions TEXT,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,

        scheduled_at TEXT NOT NULL,
        due_at TEXT NOT NULL,
        status TEXT NOT NULL,

        snooze_allowed INTEGER NOT NULL,
        default_snooze_minutes INTEGER NOT NULL,

        synced_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createReminderActionQueue(Database db) async {
    await db.execute('''
      CREATE TABLE reminder_action_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        occurrence_id TEXT NOT NULL,

        action_type TEXT NOT NULL,

        previous_status TEXT,
        new_status TEXT,

        new_due_at TEXT,
        action_note TEXT,

        created_at TEXT NOT NULL,

        queue_status TEXT NOT NULL DEFAULT 'PENDING',
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');
  }
}
