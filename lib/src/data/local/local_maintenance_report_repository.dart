import 'dart:convert';

import '../../domain/models/maintenance_report.dart';
import '../../domain/repositories/maintenance_report_repository.dart';
import 'app_database.dart';

class LocalMaintenanceReportRepository implements MaintenanceReportRepository {
  LocalMaintenanceReportRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> delete(String uuid) async {
    final db = await _database.instance;
    await db.delete(
      AppDatabase.reportsTable,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  @override
  Future<MaintenanceReport?> findByUuid(String uuid) async {
    final db = await _database.instance;
    final rows = await db.query(
      AppDatabase.reportsTable,
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapRowToReport(rows.first);
  }

  @override
  Future<List<MaintenanceReport>> list({SyncStatus? status}) async {
    final db = await _database.instance;
    final rows = await db.query(
      AppDatabase.reportsTable,
      where: status == null ? null : 'sync_status = ?',
      whereArgs: status == null ? null : [status.apiValue],
      orderBy: 'updated_at DESC',
    );

    return rows.map(_mapRowToReport).toList();
  }

  @override
  Future<List<MaintenanceReport>> pendingSync() {
    return list(status: SyncStatus.pendingSync);
  }

  @override
  Future<MaintenanceReport> save(MaintenanceReport report) async {
    final db = await _database.instance;
    final current = await findByUuid(report.uuid);

    final row = {
      'uuid': report.uuid,
      'service_date': _formatDateOnly(report.serviceDate),
      'maintenance_type': report.maintenanceType.apiValue,
      'location': report.location,
      'technician_name': report.technician.name,
      'sync_status': report.syncStatus.apiValue,
      'created_at': report.createdAt.toIso8601String(),
      'updated_at': report.updatedAt.toIso8601String(),
      'synced_at': report.syncedAt?.toIso8601String(),
      'payload_json': jsonEncode(report.toJson()),
    };

    if (current == null) {
      await db.insert(AppDatabase.reportsTable, row);
    } else {
      await db.update(
        AppDatabase.reportsTable,
        row,
        where: 'uuid = ?',
        whereArgs: [report.uuid],
      );
    }

    return (await findByUuid(report.uuid))!;
  }

  MaintenanceReport _mapRowToReport(Map<String, Object?> row) {
    final payload = Map<String, dynamic>.from(
      jsonDecode(row['payload_json']! as String) as Map,
    );

    return MaintenanceReport.fromJson(
      payload,
      localId: row['local_id'] as int?,
    );
  }

  String _formatDateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
