import 'package:flutter/material.dart';

import '../../../services/app_diagnostics_service.dart';
import '../../../services/app_error_formatter.dart';

class DebugToolsScreen extends StatefulWidget {
  const DebugToolsScreen({
    super.key,
    required this.diagnosticsService,
  });

  final AppDiagnosticsService diagnosticsService;

  @override
  State<DebugToolsScreen> createState() => _DebugToolsScreenState();
}

class _DebugToolsScreenState extends State<DebugToolsScreen> {
  late Future<AppDebugSnapshot> _snapshotFuture;
  bool _isExportingBackup = false;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.diagnosticsService.collectSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico interno'),
      ),
      body: FutureBuilder<AppDebugSnapshot>(
        future: _snapshotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(
                snapshot.error ?? StateError('Unknown error'));
          }

          final data = snapshot.requireData;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                title: 'Resumen',
                children: [
                  _InfoRow(label: 'Versión', value: data.appVersion),
                  _InfoRow(
                    label: 'Sync remoto',
                    value: data.remoteSyncEnabled ? 'Activo' : 'Desactivado',
                  ),
                  _InfoRow(
                    label: 'Auth anónima',
                    value: data.anonymousAuthEnabled ? 'Activa' : 'Desactivada',
                  ),
                  _InfoRow(
                      label: 'Proyecto Supabase',
                      value: data.supabaseProjectHost),
                  _InfoRow(
                    label: 'Usuario Supabase',
                    value: data.supabaseUserId?.trim().isNotEmpty == true
                        ? data.supabaseUserId!
                        : 'Sin sesión',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Base local',
                children: [
                  _InfoRow(
                    label: 'Base de datos',
                    value: data.databaseExists
                        ? 'Disponible (${_formatBytes(data.databaseSizeBytes)})'
                        : 'No encontrada',
                  ),
                  _InfoRow(label: 'Ruta DB', value: data.databasePath),
                  _InfoRow(label: 'Documentos app', value: data.documentsPath),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Informes locales',
                children: [
                  _InfoRow(label: 'Total', value: '${data.totalReports}'),
                  _InfoRow(
                      label: 'Pendientes', value: '${data.pendingReports}'),
                  _InfoRow(
                      label: 'Sincronizados', value: '${data.syncedReports}'),
                  _InfoRow(label: 'Con error', value: '${data.errorReports}'),
                  _InfoRow(
                    label: 'Informe activo',
                    value: data.activeEditingReportUuid ?? 'Ninguno',
                  ),
                  _InfoRow(
                    label: 'Sesión de edición',
                    value: data.sessionFileExists
                        ? data.sessionFilePath
                        : 'No existe',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Archivos locales',
                children: [
                  _InfoRow(label: 'Fotos', value: '${data.photosCount}'),
                  _InfoRow(label: 'Ruta fotos', value: data.photosPath),
                  _InfoRow(label: 'Firmas', value: '${data.signaturesCount}'),
                  _InfoRow(label: 'Ruta firmas', value: data.signaturesPath),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isExportingBackup ? null : _exportBackup,
                icon: _isExportingBackup
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.folder_zip_outlined),
                label: Text(
                  _isExportingBackup
                      ? 'Exportando respaldo...'
                      : 'Crear respaldo local (.zip)',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar diagnóstico'),
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
            'No se pudo cargar el diagnóstico.',
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

  Future<void> _reload() async {
    setState(() {
      _snapshotFuture = widget.diagnosticsService.collectSnapshot();
    });
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isExportingBackup = true;
    });

    try {
      final file = await widget.diagnosticsService.exportBackupArchive();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Respaldo guardado en ${file.path}'),
          duration: const Duration(seconds: 4),
        ),
      );
      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorFormatter.withPrefix(
              'No se pudo crear el respaldo',
              error,
              fallback: 'Intenta nuevamente más tarde.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingBackup = false;
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    }
    final megabytes = kilobytes / 1024;
    return '${megabytes.toStringAsFixed(1)} MB';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

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
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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
