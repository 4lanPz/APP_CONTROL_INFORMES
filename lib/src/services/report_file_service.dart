import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  Future<String> buildPdfOutputPath(String reportUuid) async {
    final pdfDirectory = await _ensureDirectory(['reports', 'pdf']);
    return p.join(pdfDirectory.path, '$reportUuid.pdf');
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
}

