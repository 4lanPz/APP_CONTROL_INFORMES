import 'package:flutter/material.dart';

import '../../application/report_workflow_service.dart';
import '../../config/app_config.dart';
import '../../data/remote/supabase_sync_service.dart';
import '../../domain/models/maintenance_report.dart';
import 'report_form_screen.dart';

class ReportsHomeScreen extends StatefulWidget {
  const ReportsHomeScreen({
    super.key,
    required this.reportService,
    required this.config,
  });

  final ReportWorkflowService reportService;
  final AppConfig config;

  @override
  State<ReportsHomeScreen> createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen> {
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _message;
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
        title: const Text('Informes de mantenimiento'),
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
    final statusText = widget.config.canUseSupabase
        ? 'Supabase configurado'
        : 'Supabase pendiente';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado general',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  icon: Icons.schedule,
                  label: '$pendingCount pendientes',
                  color: const Color(0xFFF0B429),
                ),
                _buildStatChip(
                  icon: Icons.cloud_done,
                  label: '$syncedCount enviados',
                  color: const Color(0xFF1F8F5F),
                ),
                _buildStatChip(
                  icon: Icons.error_outline,
                  label: '$errorCount con error',
                  color: const Color(0xFFC0392B),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Almacenamiento local activo. $statusText.',
              style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
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
              child: ListTile(
                onTap: () => _openExistingReport(report),
                title: Text(
                  report.location.trim().isEmpty
                      ? 'Informe ${report.uuid.substring(0, 8)}'
                      : report.location,
                ),
                subtitle: Text(
                  'Tecnico: ${report.technician.name.isEmpty ? '-' : report.technician.name}\n'
                  'Fecha: ${_formatDate(report.serviceDate)}\n'
                  'Actualizado: ${_formatDateTime(report.updatedAt)}',
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusBadge(report.syncStatus),
                    const SizedBox(height: 6),
                    const Icon(Icons.chevron_right),
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

  String _buildSyncMessage(SyncBatchResult result) {
    if (result.message != null && result.skipped) {
      return result.message!;
    }
    return 'Intentados: ${result.attempted}, exitosos: ${result.succeeded}, fallidos: ${result.failedUuids.length}.';
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
}
