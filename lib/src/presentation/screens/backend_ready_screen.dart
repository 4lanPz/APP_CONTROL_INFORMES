import 'package:flutter/material.dart';

import '../../application/report_workflow_service.dart';
import '../../config/app_config.dart';
import '../../data/remote/supabase_sync_service.dart';
import '../../domain/models/maintenance_report.dart';
import '../widgets/draft_app_bar_title.dart';

class BackendReadyScreen extends StatefulWidget {
  const BackendReadyScreen({
    super.key,
    required this.reportService,
    required this.config,
  });

  final ReportWorkflowService reportService;
  final AppConfig config;

  @override
  State<BackendReadyScreen> createState() => _BackendReadyScreenState();
}

class _BackendReadyScreenState extends State<BackendReadyScreen> {
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
    final pendingCount = _reports
        .where((report) => report.syncStatus == SyncStatus.pendingSync)
        .length;
    final syncedCount = _reports
        .where((report) => report.syncStatus == SyncStatus.synced)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const DraftAppBarTitle('Backend base listo'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(pendingCount, syncedCount),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: _isLoading ? null : _createDraftReport,
                  child: const Text('Crear borrador'),
                ),
                OutlinedButton(
                  onPressed: _isLoading ? null : _reload,
                  child: const Text('Recargar'),
                ),
                OutlinedButton(
                  onPressed: _isLoading || _isSyncing ? null : _syncPending,
                  child: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar'),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Informes guardados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_reports.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Todavia no hay informes. El backend ya esta conectado y listo para recibir el formulario real.',
                  ),
                ),
              )
            else
              ..._reports.map(_buildReportCard),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(int pendingCount, int syncedCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado tecnico',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('SQLite local: listo'),
            Text(
              'Supabase: ${widget.config.canUseSupabase ? 'configurado' : 'pendiente'}',
            ),
            Text('Pendientes: $pendingCount'),
            Text('Sincronizados: $syncedCount'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(MaintenanceReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(report.location.trim().isEmpty ? report.uuid : report.location),
        subtitle: Text(
          'Tecnico: ${report.technician.name.isEmpty ? '-' : report.technician.name}\n'
          'Estado: ${report.syncStatus.label}\n'
          'Fecha: ${_formatDate(report.serviceDate)}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
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

  Future<void> _createDraftReport() async {
    try {
      final draft = widget.reportService.createEmptyReport();
      await widget.reportService.saveReport(draft);

      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            'Se creo un informe base con UUID ${draft.uuid}. Luego podemos conectarlo a la plantilla visual.';
      });

      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Error creando borrador: $error';
      });
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
}
