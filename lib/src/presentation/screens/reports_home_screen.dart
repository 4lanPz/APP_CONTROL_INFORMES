import 'package:flutter/material.dart';

import '../../application/report_workflow_service.dart';
import '../../config/app_config.dart';
import '../../services/app_diagnostics_service.dart';
import '../../domain/models/maintenance_report.dart';
import '../../services/app_error_formatter.dart';
import '../../services/editing_session_service.dart';
import '../../utils/date_formats.dart';
import '../widgets/draft_app_bar_title.dart';
import 'app_status_screen.dart';
import 'developer_info_screen.dart';
import 'report_form_screen.dart';

class ReportsHomeScreen extends StatefulWidget {
  const ReportsHomeScreen({
    super.key,
    required this.reportService,
    required this.config,
    required this.editingSessionService,
    required this.diagnosticsService,
  });

  final ReportWorkflowService reportService;
  final AppConfig config;
  final EditingSessionService editingSessionService;
  final AppDiagnosticsService diagnosticsService;

  @override
  State<ReportsHomeScreen> createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen> {
  bool _isLoading = true;
  String? _pdfGeneratingUuid;
  String? _message;
  bool _didAttemptSessionRestore = false;
  List<MaintenanceReport> _reports = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final recoveredReports = _reports
        .where((report) => report.syncStatus == SyncStatus.draft)
        .toList();
    final pendingReports = _reports
        .where((report) => report.syncStatus == SyncStatus.pendingSync)
        .toList();
    final syncedReports = _reports
        .where((report) => report.syncStatus == SyncStatus.synced)
        .toList();
    final errorReports = _reports
        .where((report) => report.syncStatus == SyncStatus.syncError)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const DraftAppBarTitle('TecnoReport'),
        actions: [
          IconButton(
            tooltip: 'Estado de la app',
            onPressed: _openAppStatus,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Info',
            onPressed: _openDeveloperInfo,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewReport,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo informe'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (_message != null) ...[
              _buildMessageCard(_message!),
              const SizedBox(height: 16),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_reports.isEmpty)
              _buildEmptyState()
            else ...[
              if (recoveredReports.isNotEmpty) ...[
                _buildGroupSection(
                  title: 'Recuperados',
                  emptyLabel: 'No hay informes recuperados.',
                  reports: recoveredReports,
                  color: const Color(0xFF7F8C8D),
                  recovered: true,
                ),
                const SizedBox(height: 16),
              ],
              _buildGroupSection(
                title: 'Pendientes',
                emptyLabel: 'No hay informes pendientes.',
                reports: pendingReports,
                color: const Color(0xFFF0B429),
              ),
              const SizedBox(height: 16),
              _buildGroupSection(
                title: 'Enviados',
                emptyLabel: 'No hay informes enviados.',
                reports: syncedReports,
                color: const Color(0xFF1F8F5F),
              ),
              const SizedBox(height: 16),
              _buildGroupSection(
                title: 'Con error',
                emptyLabel: 'No hay informes con error.',
                reports: errorReports,
                color: const Color(0xFFC0392B),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(String message) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Todavía no hay informes guardados.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Usa el botón "Nuevo informe" para registrar el primer mantenimiento.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSection({
    required String title,
    required String emptyLabel,
    required List<MaintenanceReport> reports,
    required Color color,
    bool recovered = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Text(
              '(${reports.length})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (reports.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(emptyLabel),
            ),
          )
        else
          ...reports.map(
            (report) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _reportTitle(report, recovered: recovered),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Técnico: ${report.technician.name.isEmpty ? '-' : report.technician.name}',
                              ),
                              Text(
                                'Fecha: ${formatDisplayDate(report.serviceDate)}',
                              ),
                              Text(
                                'Actualizado: ${_formatDateTime(report.updatedAt)}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(report.syncStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openExistingReport(report),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _pdfGeneratingUuid == report.uuid
                                ? null
                                : () => _generatePdf(report),
                            icon: _pdfGeneratingUuid == report.uuid
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(
                              _pdfGeneratingUuid == report.uuid
                                  ? 'Generando...'
                                  : 'Generar PDF',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(SyncStatus status) {
    Color color;
    String label;

    switch (status) {
      case SyncStatus.synced:
        color = const Color(0xFF1F8F5F);
        label = 'Enviado';
      case SyncStatus.syncError:
        color = const Color(0xFFC0392B);
        label = 'Error';
      case SyncStatus.draft:
        color = const Color(0xFF7F8C8D);
        label = 'Borrador';
      case SyncStatus.pendingSync:
        color = const Color(0xFFF0B429);
        label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final reports = await widget.reportService.loadReports();
      if (!mounted) {
        return;
      }

      setState(() {
        _reports = reports;
        _isLoading = false;
      });

      if (!_didAttemptSessionRestore) {
        _didAttemptSessionRestore = true;
        await _resumeEditingSessionIfNeeded();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _message = AppErrorFormatter.withPrefix(
          'Error cargando informes',
          error,
          fallback: 'No se pudieron cargar los informes guardados.',
        );
      });
    }
  }

  Future<void> _openNewReport() async {
    final didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReportFormScreen(
          reportService: widget.reportService,
          editingSessionService: widget.editingSessionService,
        ),
      ),
    );

    if (didChange == true && mounted) {
      await _reload();
    }
  }

  Future<void> _openExistingReport(MaintenanceReport report) async {
    final didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReportFormScreen(
          reportService: widget.reportService,
          editingSessionService: widget.editingSessionService,
          initialReport: report,
        ),
      ),
    );

    if (didChange == true && mounted) {
      await _reload();
    }
  }

  Future<void> _openAppStatus() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppStatusScreen(
          diagnosticsService: widget.diagnosticsService,
          reportService: widget.reportService,
        ),
      ),
    );

    // Al volver del panel de estado pudo haberse sincronizado, así que
    // refrescamos la lista para reflejar los estados actualizados.
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _openDeveloperInfo() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DeveloperInfoScreen(diagnosticsService: widget.diagnosticsService),
      ),
    );
  }

  Future<void> _generatePdf(MaintenanceReport report) async {
    setState(() {
      _pdfGeneratingUuid = report.uuid;
    });

    try {
      final file = await widget.reportService.generatePdf(report);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_buildPdfSavedMessage(file.path)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorFormatter.withPrefix(
              'No se pudo generar el PDF',
              error,
              fallback: 'Verifica el almacenamiento del dispositivo.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pdfGeneratingUuid = null;
        });
      }
    }
  }

  /// Título mostrado en la tarjeta del informe. Los informes recuperados
  /// (borradores que quedaron incompletos, p. ej. tras un cierre inesperado)
  /// se prefijan con `recuperado_` para que el técnico los identifique.
  String _reportTitle(MaintenanceReport report, {required bool recovered}) {
    final baseName = report.location.trim().isEmpty
        ? 'Informe ${report.uuid.substring(0, 8)}'
        : report.location.trim();
    return recovered ? 'recuperado_$baseName' : baseName;
  }

  String _buildPdfSavedMessage(String filePath) {
    final normalizedPath = filePath.replaceAll('\\', '/').toLowerCase();
    if (normalizedPath.contains('/download/')) {
      return 'PDF guardado en Descargas/Informes Generados.';
    }
    return 'PDF generado correctamente: $filePath';
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${formatDisplayDate(value)} $hour:$minute';
  }

  Future<void> _resumeEditingSessionIfNeeded() async {
    final activeReportUuid =
        await widget.editingSessionService.loadActiveReportUuid();
    if (!mounted || activeReportUuid == null) {
      return;
    }

    final report = await widget.reportService.getReport(activeReportUuid);
    if (!mounted) {
      return;
    }

    if (report == null) {
      await widget.editingSessionService.clearActiveReportUuid();
      return;
    }

    final didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReportFormScreen(
          reportService: widget.reportService,
          editingSessionService: widget.editingSessionService,
          initialReport: report,
        ),
      ),
    );

    if (didChange == true && mounted) {
      await _reload();
    }
  }
}
