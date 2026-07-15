import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _databaseVersion = 2;
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
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToV2(db);
        }
      },
    );

    return _database!;
  }

  /// Solo se guardan columnas planas para lo que realmente se filtra u
  /// ordena (`sync_status`, `updated_at`); el resto del informe vive
  /// únicamente en `payload_json`, para no duplicar el mismo dato en dos
  /// formatos dentro de la misma fila.
  Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $reportsTable (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        sync_status TEXT NOT NULL,
        updated_at TEXT NOT NULL,
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
  }

  /// v1 -> v2: elimina las columnas planas que nunca se leían
  /// (`service_date`, `maintenance_type`, `location`, `technician_name`,
  /// `created_at`, `synced_at`) y que solo duplicaban lo que ya está en
  /// `payload_json`. SQLite no soporta `DROP COLUMN` en las versiones que
  /// trae Android en la mayoría de dispositivos, así que se recrea la tabla
  /// copiando los datos existentes (patrón estándar de migración en
  /// SQLite).
  Future<void> _migrateToV2(DatabaseExecutor db) async {
    await db.execute('ALTER TABLE $reportsTable RENAME TO reports_old');
    // Los índices viejos quedan asociados a `reports_old` (SQLite no los
    // renombra), así que hay que soltar esos nombres antes de recrearlos
    // sobre la tabla nueva.
    await db.execute('DROP INDEX IF EXISTS idx_reports_sync_status');
    await db.execute('DROP INDEX IF EXISTS idx_reports_updated_at');
    await _createSchema(db);
    await db.execute('''
      INSERT INTO $reportsTable (local_id, uuid, sync_status, updated_at, payload_json)
      SELECT local_id, uuid, sync_status, updated_at, payload_json FROM reports_old
    ''');
    await db.execute('DROP TABLE reports_old');
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
