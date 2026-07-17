import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'bootstrap/app_bootstrap.dart';
import 'presentation/screens/locked_screen.dart';
import 'presentation/screens/reports_home_screen.dart';
import 'services/license_service.dart';

class MaintenanceReportsApp extends StatelessWidget {
  const MaintenanceReportsApp({
    super.key,
    required this.bootstrap,
  });

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TecnoReport',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'EC'),
      supportedLocales: const [Locale('es', 'EC'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF184A45),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _LicenseGateView(bootstrap: bootstrap),
    );
  }
}

/// Único punto de control de la licencia: si está bloqueada muestra la pantalla
/// de bloqueo; si no, la app normal. Permite reintentar la verificación sin
/// reiniciar (por si el proveedor la reactiva en Supabase).
class _LicenseGateView extends StatefulWidget {
  const _LicenseGateView({required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<_LicenseGateView> createState() => _LicenseGateViewState();
}

class _LicenseGateViewState extends State<_LicenseGateView> {
  late LicenseGate _gate;

  @override
  void initState() {
    super.initState();
    _gate = widget.bootstrap.licenseGate;
  }

  Future<void> _recheck() async {
    final gate = await widget.bootstrap.licenseService.evaluate();
    if (mounted) {
      setState(() => _gate = gate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gate.locked) {
      return LockedScreen(
        reason: _gate.reason,
        onRetry: _recheck,
      );
    }

    return ReportsHomeScreen(
      reportService: widget.bootstrap.reportService,
      config: widget.bootstrap.config,
      editingSessionService: widget.bootstrap.editingSessionService,
      diagnosticsService: widget.bootstrap.diagnosticsService,
    );
  }
}
