import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EditingSessionService {
  static const _sessionFileName = 'active_editing_session.txt';

  Future<void> saveActiveReportUuid(String uuid) async {
    final file = await _sessionFile;
    await file.writeAsString(uuid.trim(), flush: true);
  }

  Future<String?> loadActiveReportUuid() async {
    final file = await _sessionFile;
    if (!await file.exists()) {
      return null;
    }

    final value = (await file.readAsString()).trim();
    return value.isEmpty ? null : value;
  }

  Future<void> clearActiveReportUuid() async {
    final file = await _sessionFile;
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> get _sessionFile async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return File(p.join(documentsDirectory.path, _sessionFileName));
  }
}
