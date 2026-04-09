import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models/maintenance_report.dart';

enum ReportPhotoType {
  before,
  after,
}

class ReportFileService {
  Future<String> persistPhoto({
    required String reportUuid,
    required String sourcePath,
    required ReportPhotoType type,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Photo file not found.', sourcePath);
    }

    final photosDirectory = await _ensureDirectory(['reports', 'photos']);
    final extension = p.extension(sourcePath);
    final suffix = type == ReportPhotoType.before ? 'before' : 'after';
    final targetPath = p.join(
      photosDirectory.path,
      '${reportUuid}_$suffix$extension',
    );

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  Future<String> buildPdfOutputPath(MaintenanceReport report) async {
    final pdfDirectory = await _ensurePdfDirectory();
    final generatedAt = DateTime.now();
    final technicianName = _sanitizeFileSegment(
      report.technician.name.trim().isEmpty
          ? 'Tecnico'
          : report.technician.name,
    );
    final timestamp = _formatTimestamp(generatedAt);
    final fileName = 'Informe_${technicianName}_$timestamp.pdf';
    return p.join(pdfDirectory.path, fileName);
  }

  Future<Directory> _ensureDirectory(List<String> fragments) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directoryPath = p.joinAll([documentsDirectory.path, ...fragments]);
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory> _ensurePdfDirectory() async {
    final documentsDirectories = await getExternalStorageDirectories(
      type: StorageDirectory.documents,
    );

    if (documentsDirectories != null && documentsDirectories.isNotEmpty) {
      final directory = Directory(
        p.join(documentsDirectories.first.path, 'Informes Generados'),
      );
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }

    return _ensureDirectory(['Informes Generados']);
  }

  String _sanitizeFileSegment(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    final sanitized = compact.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    return sanitized.isEmpty ? 'Tecnico' : sanitized;
  }

  String _formatTimestamp(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day-$month-$year-$hour-$minute';
  }
}
