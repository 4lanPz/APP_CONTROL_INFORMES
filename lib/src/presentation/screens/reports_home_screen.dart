import 'package:flutter/material.dart';

import '../../application/report_workflow_service.dart';
import '../../config/app_config.dart';
import '../../data/remote/supabase_sync_service.dart';
import '../../domain/models/maintenance_report.dart';
import '../../services/editing_session_service.dart';
import '../widgets/draft_app_bar_title.dart';
import 'report_form_screen.dart';

class ReportsHomeScreen extends StatefulWidget {
  const ReportsHomeScreen({
    super.key,
    required this.reportService,
    required this.config,
    required this.editingSessionService,
  });

  final ReportWorkflowService reportService;
  final AppConfig config;
  final EditingSessionService editingSessionService;

  @override
  State<ReportsHomeScreen> createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen> {
  bool _isLoading = true;
  bool _isSyncing = false;
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
        title: const DraftAppBarTitle('Informes de mantenimiento'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar pendientes',
            onPressed: _isLoading || _isSyncing ? null : _syncPending,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.sync),
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
            _buildSummaryCard(
              pendingCount: pendingReports.length,
              syncedCount: syncedReports.length,
              errorCount: errorReports.length,
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              _buildMessageCard(_message!),
            ],
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_reports.isEmpty)
              _buildEmptyState()
            else ...[
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

  Widget _buildSummaryCard({
    required int pendingCount,
    required int syncedCount,
    required int errorCount,
  }) {
    final isLocalReady = true;
    final isOnlineReady = widget.config.canUseSupabase;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado general',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    title: 'Pendientes',
                    value: '$pendingCount',
                    color: const Color(0xFFF0B429),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat(
                    title: 'Enviados',
                    value: '$syncedCount',
                    color: const Color(0xFF1F8F5F),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMiniStat(
                    title: 'Con error',
                    value: '$errorCount',
                    color: const Color(0xFFC0392B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBaseStatus(
                    title: 'Estado base local',
                    isReady: isLocalReady,
                    successLabel: 'Correcto',
                    errorLabel: 'Fallando',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBaseStatus(
                    title: 'Estado base online',
                    isReady: isOnlineReady,
                    successLabel: 'Correcto',
                    errorLabel: 'Pendiente',
                  ),
                ),
              ],
            ),
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

  Widget _buildMiniStat({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseStatus({
    required String title,
    required bool isReady,
    required String successLabel,
    required String errorLabel,
  }) {
    final color = isReady ? const Color(0xFF1F8F5F) : const Color(0xFFC0392B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isReady ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isReady ? successLabel : errorLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
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
              'Todavia no hay informes guardados.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Usa el boton "Nuevo informe" para registrar el primer mantenimiento.',
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
                                report.location.trim().isEmpty
                                    ? 'Informe ${report.uuid.substring(0, 8)}'
                                    : report.location,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tecnico: ${report.technician.name.isEmpty ? '-' : report.technician.name}',
                              ),
                              Text(
                                'Fecha: ${_formatDate(report.serviceDate)}',
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
        _message = 'Error cargando informes: $error';
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

  Future<void> _syncPending() async {
    setState(() {
      _isSyncing = true;
      _message = null;
    });

    try {
      final result = await widget.reportService.syncPendingReports();
      if (!mounted) {
        return;
      }

      setState(() {
        _isSyncing = false;
        _message = _buildSyncMessage(result);
      });

      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSyncing = false;
        _message = 'Error sincronizando: $error';
      });
    }
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
          content: Text('No se pudo generar el PDF: $error'),
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

  String _buildSyncMessage(SyncBatchResult result) {
    if (result.message != null && result.skipped) {
      return result.message!;
    }
    return 'Intentados: ${result.attempted}, exitosos: ${result.succeeded}, fallidos: ${result.failedUuids.length}.';
  }

  String _buildPdfSavedMessage(String filePath) {
    final normalizedPath = filePath.replaceAll('\\', '/').toLowerCase();
    if (normalizedPath.contains('/download/')) {
      return 'PDF guardado en Descargas/Informes Generados.';
    }
    return 'PDF generado correctamente: $filePath';
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${_formatDate(value)} $hour:$minute';
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
