import 'package:flutter/material.dart';

/// Pantalla que se muestra cuando la licencia está bloqueada (kill switch).
///
/// Al estar aquí, la app no permite crear informes, generar PDF ni sincronizar
/// (es el único punto de entrada cuando el estado es "bloqueado").
class LockedScreen extends StatefulWidget {
  const LockedScreen({
    super.key,
    required this.onRetry,
    this.reason,
  });

  /// Reevalúa la licencia (por si el proveedor ya la reactivó en Supabase).
  final Future<void> Function() onRetry;

  final String? reason;

  @override
  State<LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends State<LockedScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = widget.reason?.trim();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 72,
                  color: Color(0xFF8C1C13),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aplicación desactivada',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  reason == null || reason.isEmpty
                      ? 'Esta aplicación no está habilitada. Contacta al '
                          'proveedor para reactivarla.'
                      : reason,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _checking ? null : _retry,
                  icon: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _checking ? 'Verificando...' : 'Verificar de nuevo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Conéctate a internet y toca "Verificar de nuevo" una vez '
                  'reactivada.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
