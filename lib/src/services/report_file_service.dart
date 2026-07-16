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

  Future<String> persistSignature({
    required String reportUuid,
    required String suffix,
    required List<int> bytes,
  }) async {
    final signaturesDirectory = await _ensureDirectory([
      'reports',
      'signatures',
    ]);
    final targetPath = p.join(
      signaturesDirectory.path,
      '${reportUuid}_$suffix.png',
    );

    final signatureBytes =
        bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    await File(targetPath).writeAsBytes(signatureBytes, flush: true);
    return targetPath;
  }

  /// Borra del disco un archivo de foto/firma ya persistido (best-effort: si
  /// no existe o falla al borrarse, no lanza error).
  Future<void> deleteFile(String path) async {
    if (path.trim().isEmpty) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort: no bloqueamos la edición del formulario por esto.
    }
  }

  /// Escribe el PDF en la caché interna de la app (no en Descargas). Es un
  /// archivo de paso: [openPdfExternally] lo entrega a otra app vía
  /// FileProvider para que el técnico decida ahí si lo guarda o lo comparte.
  Future<File> savePdfToCache({
    required MaintenanceReport report,
    required List<int> bytes,
  }) async {
    final generatedAt = DateTime.now();
    final fileName = _buildPdfFileName(report, generatedAt);
    final directory = await _ensureCacheDirectory(['reports', 'pdf']);
    final fileBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(fileBytes, flush: true);
    return file;
  }

  /// Abre el PDF con el selector nativo de Android ("Abrir con"), para que el
  /// técnico elija una app instalada para verlo y desde ahí decida si lo
  /// guarda o lo comparte.
  Future<void> openPdfExternally(File file) async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _storageChannel.invokeMethod<void>('openPdfExternally', {
        'path': file.path,
      });
    } on MissingPluginException {
      throw FileSystemException(
        'La apertura de PDF con otra aplicación no está disponible en este dispositivo.',
      );
    } on PlatformException catch (error) {
      throw FileSystemException(
        error.message ?? 'No se pudo abrir el PDF con otra aplicación.',
      );
    }
  }

  Future<File> saveBytesToDownloads({
    required String fileName,
    required String subdirectory,
    required String mimeType,
    required List<int> bytes,
    required List<String> fallbackDirectoryFragments,
    required String storageUnavailableMessage,
    required String saveFailedMessage,
    required String missingPathMessage,
  }) async {
    final fileBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    if (Platform.isAndroid) {
      try {
        final savedPath = await _storageChannel.invokeMethod<String>(
          'saveBytesToDownloads',
          {
            'fileName': fileName,
            'subdirectory': subdirectory,
            'mimeType': mimeType,
            'bytes': fileBytes,
          },
        );

        if (savedPath != null && savedPath.trim().isNotEmpty) {
          return File(savedPath);
        }

        throw FileSystemException(missingPathMessage);
      } on MissingPluginException {
        throw FileSystemException(storageUnavailableMessage);
      } on PlatformException {
        throw FileSystemException(saveFailedMessage);
      }
    }

    final outputDirectory = await _ensureDirectory(fallbackDirectoryFragments);
    final file = File(p.join(outputDirectory.path, fileName));
    await file.writeAsBytes(fileBytes, flush: true);
    return file;
  }

  Future<Directory> getDocumentsDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  Future<Directory> getPhotosDirectory() async {
    return _ensureDirectory(['reports', 'photos']);
  }

  Future<Directory> getSignaturesDirectory() async {
    return _ensureDirectory(['reports', 'signatures']);
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

  Future<Directory> _ensureDirectory(List<String> fragments) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final directoryPath = p.joinAll([documentsDirectory.path, ...fragments]);
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory> _ensureCacheDirectory(List<String> fragments) async {
    final cacheDirectory = await getTemporaryDirectory();
    final directoryPath = p.joinAll([cacheDirectory.path, ...fragments]);
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
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
