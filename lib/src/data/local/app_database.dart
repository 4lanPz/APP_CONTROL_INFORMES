import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _databaseVersion = 1;
  static const reportsTable = 'reports';

  AppDatabase({
    required this.databaseName,
  });

  final String databaseName;

  Database? _database;

  Future<Database> open() async {
    if (_database != null) {
      return _database!;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $reportsTable (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            service_date TEXT NOT NULL,
            maintenance_type TEXT NOT NULL,
            location TEXT NOT NULL,
            technician_name TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            synced_at TEXT,
            payload_json TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_reports_sync_status
          ON $reportsTable (sync_status)
        ''');
        await db.execute('''
          CREATE INDEX idx_reports_updated_at
          ON $reportsTable (updated_at DESC)
        ''');
      },
    );

    return _database!;
  }

  Future<Database> get instance async => open();

  Future<void> close() async {
    if (_database == null) {
      return;
    }
    await _database!.close();
    _database = null;
  }
}
