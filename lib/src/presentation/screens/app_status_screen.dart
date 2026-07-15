import 'package:flutter/material.dart';

import '../../application/report_workflow_service.dart';
import '../../data/remote/supabase_sync_service.dart';
import '../../services/app_diagnostics_service.dart';
import '../../services/app_error_formatter.dart';

/// Panel de estado de la app (icono de engranaje del home).
///
/// Muestra, en un solo lugar y fuera de la vista del técnico:
///  1. Estado de la base local.
///  2. Estado de la base Supabase.
///  3. Estado de los archivos (pendientes / enviados / con error).
///  4. UUID del usuario actual.
///
/// Además concentra la acción de sincronizar pendientes, que antes vivía en el
/// botón de la pantalla principal.
class AppStatusScreen extends StatefulWidget {
  const AppStatusScreen({
    super.key,
    required this.diagnosticsService,
    required this.reportService,
  });

  final AppDiagnosticsService diagnosticsService;
  final ReportWorkflowService reportService;

  @override
  State<AppStatusScreen> createState() => _AppStatusScreenState();
}

class _AppStatusScreenState extends State<AppStatusScreen> {
  late Future<AppDebugSnapshot> _snapshotFuture;
  bool _isSyncing = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.diagnosticsService.collectSnapshot();
  }

  Future<void> _reload() async {
    setState(() {
      _snapshotFuture = widget.diagnosticsService.collectSnapshot();
    });
  }

  Future<void> _syncPending() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });

    try {
      final result = await widget.reportService.syncPendingReports();
      if (!mounted) {
        return;
      }
      setState(() {
        _syncMessage = _buildSyncMessage(result);
      });
      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _syncMessage = AppErrorFormatter.withPrefix(
          'Error sincronizando',
          error,
          fallback: 'No se pudieron sincronizar los informes pendientes.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  String _buildSyncMessage(SyncBatchResult result) {
    if (result.message != null && result.skipped) {
      return result.message!;
    }

    final summary =
        'Intentados: ${result.attempted}, exitosos: ${result.succeeded}, fallidos: ${result.failedUuids.length}.';
    if (result.failedDetails.isEmpty) {
      return summary;
    }

    final firstError = result.failedDetails.values.first;
    return '$summary Primer error: $firstError';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de la app'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<AppDebugSnapshot>(
        future: _snapshotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(
              snapshot.error ?? StateError('Unknown error'),
            );
          }

          final data = snapshot.requireData;
          final hasSupabaseSession =
              data.supabaseUserId?.trim().isNotEmpty == true;

          return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Base local.
                _StatusSection(
                  title: 'Base local',
                  headline: _StatusHeadline(
                    isOk: data.databaseExists,
                    okLabel: 'Correcta',
                    errorLabel: 'Con falla',
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Base Supabase.
                _StatusSection(
                  title: 'Base Supabase',
                  headline: _StatusHeadline(
                    isOk: data.remoteSyncEnabled,
                    okLabel: 'Correcta',
                    errorLabel: 'Con falla',
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Archivos / informes.
                _StatusSection(
                  title: 'Informes',
                  rows: [
                    _InfoRow(label: 'Total', value: '${data.totalReports}'),
                    _InfoRow(
                      label: 'Pendientes de envío',
                      value: '${data.pendingReports}',
                    ),
                    _InfoRow(
                      label: 'Enviados',
                      value: '${data.syncedReports}',
                    ),
                    _InfoRow(
                      label: 'Con error',
                      value: '${data.errorReports}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Usuario actual.
                _StatusSection(
                  title: 'Usuario actual',
                  rows: [
                    _InfoRow(
                      label: 'UUID',
                      value: hasSupabaseSession
                          ? data.supabaseUserId!
                          : 'Sin sesión',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_syncMessage != null) ...[
                  Card(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_syncMessage!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                FilledButton.icon(
                  onPressed: (!data.remoteSyncEnabled || _isSyncing)
                      ? null
                      : _syncPending,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    _isSyncing
                        ? 'Sincronizando...'
                        : 'Sincronizar pendientes',
                  ),
                ),
                if (!data.remoteSyncEnabled)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'La sincronización remota está desactivada en esta '
                      'compilación.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        ),
      );
  }

  Widget _buildErrorState(Object error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No se pudo cargar el estado.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            AppErrorFormatter.format(
              error,
              fallback: 'Intenta abrir esta pantalla nuevamente.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.title,
    this.rows = const [],
    this.headline,
  });

  final String title;
  final List<Widget> rows;
  final _StatusHeadline? headline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (headline != null) ...[
              const SizedBox(height: 10),
              headline!,
            ],
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...rows,
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusHeadline extends StatelessWidget {
  const _StatusHeadline({
    required this.isOk,
    required this.okLabel,
    required this.errorLabel,
  });

  final bool isOk;
  final String okLabel;
  final String errorLabel;

  @override
  Widget build(BuildContext context) {
    final color = isOk ? const Color(0xFF1F8F5F) : const Color(0xFFC0392B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOk ? okLabel : errorLabel,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 2),
          SelectableText(value),
        ],
      ),
    );
  }
}
