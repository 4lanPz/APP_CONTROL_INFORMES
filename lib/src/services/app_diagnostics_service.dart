import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../domain/models/maintenance_report.dart';
import '../domain/repositories/maintenance_report_repository.dart';
import 'editing_session_service.dart';
import 'report_file_service.dart';

class AppDebugSnapshot {
  const AppDebugSnapshot({
    required this.appVersion,
    required this.documentsPath,
    required this.databasePath,
    required this.databaseExists,
    required this.databaseSizeBytes,
    required this.totalReports,
    required this.pendingReports,
    required this.syncedReports,
    required this.errorReports,
    required this.activeEditingReportUuid,
    required this.sessionFilePath,
    required this.sessionFileExists,
    required this.photosPath,
    required this.photosCount,
    required this.signaturesPath,
    required this.signaturesCount,
    required this.remoteSyncEnabled,
    required this.anonymousAuthEnabled,
    required this.supabaseProjectHost,
    required this.supabaseUserId,
  });

  final String appVersion;
  final String documentsPath;
  final String databasePath;
  final bool databaseExists;
  final int databaseSizeBytes;
  final int totalReports;
  final int pendingReports;
  final int syncedReports;
  final int errorReports;
  final String? activeEditingReportUuid;
  final String sessionFilePath;
  final bool sessionFileExists;
  final String photosPath;
  final int photosCount;
  final String signaturesPath;
  final int signaturesCount;
  final bool remoteSyncEnabled;
  final bool anonymousAuthEnabled;
  final String supabaseProjectHost;
  final String? supabaseUserId;

  Map<String, dynamic> toJson() {
    return {
      'app_version': appVersion,
      'documents_path': documentsPath,
      'database_path': databasePath,
      'database_exists': databaseExists,
      'database_size_bytes': databaseSizeBytes,
      'total_reports': totalReports,
      'pending_reports': pendingReports,
      'synced_reports': syncedReports,
      'error_reports': errorReports,
      'active_editing_report_uuid': activeEditingReportUuid,
      'session_file_path': sessionFilePath,
      'session_file_exists': sessionFileExists,
      'photos_path': photosPath,
      'photos_count': photosCount,
      'signatures_path': signaturesPath,
      'signatures_count': signaturesCount,
      'remote_sync_enabled': remoteSyncEnabled,
      'anonymous_auth_enabled': anonymousAuthEnabled,
      'supabase_project_host': supabaseProjectHost,
      'supabase_user_id': supabaseUserId,
    };
  }
}

class AppDiagnosticsService {
  const AppDiagnosticsService({
    required this.config,
    required this.repository,
    required this.fileService,
    required this.editingSessionService,
  });

  static const appVersionLabel = 'Versión 0.9';
  static const _backupSubdirectory = 'TecnoReport Backups';

  final AppConfig config;
  final MaintenanceReportRepository repository;
  final ReportFileService fileService;
  final EditingSessionService editingSessionService;

  Future<AppDebugSnapshot> collectSnapshot() async {
    final documentsDirectory = await fileService.getDocumentsDirectory();
    final reports = await repository.list();
    final databaseFile = File(
      p.join(documentsDirectory.path, config.localDatabaseName),
    );
    final sessionFile = File(
      p.join(documentsDirectory.path, 'active_editing_session.txt'),
    );
    final photosDirectory = await fileService.getPhotosDirectory();
    final signaturesDirectory = await fileService.getSignaturesDirectory();

    final databaseExists = await databaseFile.exists();
    final databaseSizeBytes = databaseExists ? await databaseFile.length() : 0;
    final sessionFileExists = await sessionFile.exists();
    final photoFiles = await _listFiles(photosDirectory);
    final signatureFiles = await _listFiles(signaturesDirectory);
    final activeEditingUuid =
        await editingSessionService.loadActiveReportUuid();
    final supabaseUserId = config.canUseSupabase
        ? Supabase.instance.client.auth.currentUser?.id
        : null;

    return AppDebugSnapshot(
      appVersion: appVersionLabel,
      documentsPath: documentsDirectory.path,
      databasePath: databaseFile.path,
      databaseExists: databaseExists,
      databaseSizeBytes: databaseSizeBytes,
      totalReports: reports.length,
      pendingReports: reports
          .where((report) => report.syncStatus == SyncStatus.pendingSync)
          .length,
      syncedReports: reports
          .where((report) => report.syncStatus == SyncStatus.synced)
          .length,
      errorReports: reports
          .where((report) => report.syncStatus == SyncStatus.syncError)
          .length,
      activeEditingReportUuid: activeEditingUuid,
      sessionFilePath: sessionFile.path,
      sessionFileExists: sessionFileExists,
      photosPath: photosDirectory.path,
      photosCount: photoFiles.length,
      signaturesPath: signaturesDirectory.path,
      signaturesCount: signatureFiles.length,
      remoteSyncEnabled: config.canUseSupabase,
      anonymousAuthEnabled: config.useSupabaseAnonymousAuth,
      supabaseProjectHost: _buildSupabaseProjectHost(config.supabaseUrl),
      supabaseUserId: supabaseUserId,
    );
  }

  Future<File> exportBackupArchive() async {
    final documentsDirectory = await fileService.getDocumentsDirectory();
    final reports = await repository.list();
    final snapshot = await collectSnapshot();
    final archive = Archive();
    final generatedAt = DateTime.now();
    final databaseFile = File(
      p.join(documentsDirectory.path, config.localDatabaseName),
    );
    final sessionFile = File(
      p.join(documentsDirectory.path, 'active_editing_session.txt'),
    );
    final photosDirectory = await fileService.getPhotosDirectory();
    final signaturesDirectory = await fileService.getSignaturesDirectory();

    _addStringFile(
      archive,
      'manifest/debug_snapshot.json',
      const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
    );
    _addStringFile(
      archive,
      'reports/reports.json',
      const JsonEncoder.withIndent('  ').convert(
        reports.map((report) => report.toJson()).toList(growable: false),
      ),
    );
    _addStringFile(
      archive,
      'manifest/backup_info.json',
      const JsonEncoder.withIndent('  ').convert({
        'generated_at': generatedAt.toIso8601String(),
        'app_version': appVersionLabel,
        'database_name': config.localDatabaseName,
        'reports_table': config.supabaseReportsTable,
      }),
    );

    await _addFileIfExists(
      archive,
      'database/${config.localDatabaseName}',
      databaseFile,
    );
    await _addFileIfExists(
      archive,
      'session/active_editing_session.txt',
      sessionFile,
    );
    await _addDirectoryFiles(
      archive,
      sourceDirectory: photosDirectory,
      targetPrefix: 'files/photos',
    );
    await _addDirectoryFiles(
      archive,
      sourceDirectory: signaturesDirectory,
      targetPrefix: 'files/signatures',
    );

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw const FileSystemException(
        'No se pudo generar el archivo de respaldo.',
      );
    }

    final fileName = 'TecnoReport_Backup_${_formatTimestamp(generatedAt)}.zip';
    return fileService.saveBytesToDownloads(
      fileName: fileName,
      subdirectory: _backupSubdirectory,
      mimeType: 'application/zip',
      bytes: Uint8List.fromList(zipBytes),
      fallbackDirectoryFragments: const ['TecnoReport Backups'],
      storageUnavailableMessage:
          'La exportación de respaldos no está disponible en este dispositivo.',
      saveFailedMessage: 'No se pudo guardar el respaldo en Descargas.',
      missingPathMessage:
          'No se pudo confirmar la ruta del respaldo exportado.',
    );
  }

  Future<List<File>> _listFiles(Directory directory) async {
    if (!await directory.exists()) {
      return const [];
    }

    final entities = await directory.list().toList();
    return entities.whereType<File>().toList(growable: false);
  }

  void _addStringFile(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  Future<void> _addFileIfExists(
    Archive archive,
    String targetPath,
    File file,
  ) async {
    if (!await file.exists()) {
      return;
    }

    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(targetPath, bytes.length, bytes));
  }

  Future<void> _addDirectoryFiles(
    Archive archive, {
    required Directory sourceDirectory,
    required String targetPrefix,
  }) async {
    if (!await sourceDirectory.exists()) {
      return;
    }

    await for (final entity in sourceDirectory.list(recursive: true)) {
      if (entity is! File) {
        continue;
      }

      final relativePath = p.relative(entity.path, from: sourceDirectory.path);
      final bytes = await entity.readAsBytes();
      archive.addFile(
        ArchiveFile(
          p.join(targetPrefix, relativePath).replaceAll('\\', '/'),
          bytes.length,
          bytes,
        ),
      );
    }
  }

  String _buildSupabaseProjectHost(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    return uri?.host ?? '-';
  }

  String _formatTimestamp(DateTime value) {
    final year = value.year.toString();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$year$month$day' '_$hour$minute$second';
  }
}
