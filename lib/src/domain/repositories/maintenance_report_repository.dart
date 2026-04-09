import '../models/maintenance_report.dart';

abstract class MaintenanceReportRepository {
  Future<MaintenanceReport> save(MaintenanceReport report);
  Future<MaintenanceReport?> findByUuid(String uuid);
  Future<List<MaintenanceReport>> list({SyncStatus? status});
  Future<List<MaintenanceReport>> pendingSync();
  Future<void> delete(String uuid);
}
