import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../domain/models/maintenance_report.dart';
import '../../services/app_error_formatter.dart';

class SyncBatchResult {
  const SyncBatchResult({
    this.successfulUuids = const [],
    this.failedUuids = const [],
    this.failedDetails = const {},
    this.skipped = false,
    this.message,
  });

  final List<String> successfulUuids;
  final List<String> failedUuids;
  final Map<String, String> failedDetails;
  final bool skipped;
  final String? message;

  int get attempted => successfulUuids.length + failedUuids.length;
  int get succeeded => successfulUuids.length;
}

class SupabaseSyncService {
  const SupabaseSyncService({
    required this.config,
  });

  final AppConfig config;

  bool get isEnabled => config.canUseSupabase;

  Future<SyncBatchResult> syncReports(List<MaintenanceReport> reports) async {
    if (reports.isEmpty) {
      return const SyncBatchResult(
        skipped: true,
        message: 'No hay informes pendientes por sincronizar.',
      );
    }

    if (!isEnabled) {
      return const SyncBatchResult(
        skipped: true,
        message: 'Supabase no está configurado en este build.',
      );
    }

    final client = Supabase.instance.client;
    await _ensureAuthenticated(client);

    final successfulUuids = <String>[];
    final failedUuids = <String>[];
    final failedDetails = <String, String>{};
    final ownerUserId = client.auth.currentUser?.id;
    if (ownerUserId == null || ownerUserId.trim().isEmpty) {
      return const SyncBatchResult(
        skipped: true,
        message:
            'No se pudo autenticar con Supabase. Verifica la anon key y la autenticación anónima.',
      );
    }

    for (final report in reports) {
      try {
        await client.from(config.supabaseReportsTable).upsert(
              _toRemoteRow(report, ownerUserId: ownerUserId),
              onConflict: 'uuid',
            );
        successfulUuids.add(report.uuid);
      } catch (error) {
        failedUuids.add(report.uuid);
        failedDetails[report.uuid] = AppErrorFormatter.format(
          error,
          fallback: 'No se pudo sincronizar este informe.',
        );
      }
    }

    return SyncBatchResult(
      successfulUuids: successfulUuids,
      failedUuids: failedUuids,
      failedDetails: failedDetails,
      message: failedUuids.isEmpty
          ? 'Sincronización completada.'
          : 'Sincronización parcial. Revisa los informes con error.',
    );
  }

  Future<void> _ensureAuthenticated(SupabaseClient client) async {
    if (!config.useSupabaseAnonymousAuth) {
      return;
    }

    if (client.auth.currentSession != null) {
      return;
    }

    await client.auth.signInAnonymously();
  }

  Map<String, dynamic> _toRemoteRow(
    MaintenanceReport report, {
    required String? ownerUserId,
  }) {
    final syncedAt = DateTime.now().toUtc().toIso8601String();

    return {
      'uuid': report.uuid,
      'owner_user_id': ownerUserId,
      'service_date': _formatDateOnly(report.serviceDate),
      'maintenance_type': report.maintenanceType.apiValue,
      'location': report.location,
      'technician_name': report.technician.name,
      'sync_status': SyncStatus.synced.apiValue,
      'report_json': report
          .copyWith(
            syncStatus: SyncStatus.synced,
            syncedAt: DateTime.parse(syncedAt),
          )
          .toJson(),
      'created_at': report.createdAt.toUtc().toIso8601String(),
      'updated_at': report.updatedAt.toUtc().toIso8601String(),
      'synced_at': syncedAt,
    };
  }

  String _formatDateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
