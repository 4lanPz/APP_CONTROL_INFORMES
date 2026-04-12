import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/report_workflow_service.dart';
import '../config/app_config.dart';
import '../data/local/app_database.dart';
import '../data/local/local_maintenance_report_repository.dart';
import '../data/remote/supabase_sync_service.dart';
import '../services/app_diagnostics_service.dart';
import '../services/editing_session_service.dart';
import '../services/report_file_service.dart';
import '../services/report_pdf_service.dart';
import '../services/report_validator.dart';

class AppBootstrap {
  AppBootstrap({
    required this.config,
    required this.database,
    required this.reportRepository,
    required this.fileService,
    required this.editingSessionService,
    required this.pdfService,
    required this.syncService,
    required this.validator,
    required this.reportService,
    required this.diagnosticsService,
  });

  final AppConfig config;
  final AppDatabase database;
  final LocalMaintenanceReportRepository reportRepository;
  final ReportFileService fileService;
  final EditingSessionService editingSessionService;
  final ReportPdfService pdfService;
  final SupabaseSyncService syncService;
  final ReportValidator validator;
  final ReportWorkflowService reportService;
  final AppDiagnosticsService diagnosticsService;

  static Future<AppBootstrap> create() async {
    WidgetsFlutterBinding.ensureInitialized();

    final config = AppConfig.fromEnvironment();
    if (config.canUseSupabase) {
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
      );
    }

    final database = AppDatabase(
      databaseName: config.localDatabaseName,
    );
    await database.open();

    final reportRepository = LocalMaintenanceReportRepository(database);
    final fileService = ReportFileService();
    final editingSessionService = EditingSessionService();
    final pdfService = ReportPdfService(fileService);
    final syncService = SupabaseSyncService(config: config);
    final validator = ReportValidator();
    final reportService = ReportWorkflowService(
      repository: reportRepository,
      fileService: fileService,
      pdfService: pdfService,
      syncService: syncService,
      validator: validator,
    );
    final diagnosticsService = AppDiagnosticsService(
      config: config,
      repository: reportRepository,
      fileService: fileService,
      editingSessionService: editingSessionService,
    );

    return AppBootstrap(
      config: config,
      database: database,
      reportRepository: reportRepository,
      fileService: fileService,
      editingSessionService: editingSessionService,
      pdfService: pdfService,
      syncService: syncService,
      validator: validator,
      reportService: reportService,
      diagnosticsService: diagnosticsService,
    );
  }
}
