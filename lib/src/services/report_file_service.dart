import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models/maintenance_report.dart';

enum ReportPhotoType {
  before,
  after,
}

class ReportFileService {
  static const MethodChannel _storageChannel = MethodChannel(
    'app_control_informes/storage',
  );

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
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final targetPath = p.join(
      photosDirectory.path,
      '${reportUuid}_${suffix}_$timestamp$extension',
    );

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  Future<String> persistTechnicianSignature({
    required String reportUuid,
    required List<int> bytes,
  }) async {
    final signaturesDirectory = await _ensureDirectory([
      'reports',
      'signatures',
    ]);
    final targetPath = p.join(
      signaturesDirectory.path,
      '${reportUuid}_technician_signature.png',
    );

    final signatureBytes =
        bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    await File(targetPath).writeAsBytes(signatureBytes, flush: true);
    return targetPath;
  }

  Future<File> savePdf({
    required MaintenanceReport report,
    required List<int> bytes,
  }) async {
    final generatedAt = DateTime.now();
    final fileName = _buildPdfFileName(report, generatedAt);
    final pdfBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    if (Platform.isAndroid) {
      try {
        final savedPath = await _storageChannel.invokeMethod<String>(
          'savePdfToDownloads',
          {
            'fileName': fileName,
            'subdirectory': 'Informes Generados',
            'bytes': pdfBytes,
          },
        );

        if (savedPath != null && savedPath.trim().isNotEmpty) {
          return File(savedPath);
        }

        throw const FileSystemException(
          'No se pudo confirmar la ruta del PDF en Descargas.',
        );
      } on MissingPluginException {
        throw const FileSystemException(
          'La integracion con Descargas no esta disponible en este dispositivo.',
        );
      } on PlatformException {
        throw const FileSystemException(
          'No se pudo guardar el PDF en la carpeta Descargas.',
        );
      }
    }

    final outputPath = await _buildFallbackPdfOutputPath(fileName);
    final file = File(outputPath);
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  String _buildPdfFileName(
    MaintenanceReport report,
    DateTime generatedAt,
  ) {
    final technicianName = _sanitizeFileSegment(
      report.technician.name.trim().isEmpty
          ? 'Tecnico'
          : report.technician.name,
    );
    final timestamp = _formatTimestamp(generatedAt);
    return 'Informe_${technicianName}_$timestamp.pdf';
  }

  Future<String> _buildFallbackPdfOutputPath(String fileName) async {
    final pdfDirectory = await _ensureFallbackPdfDirectory();
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

  Future<Directory> _ensureFallbackPdfDirectory() async {
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
