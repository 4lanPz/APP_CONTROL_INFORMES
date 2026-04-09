import 'package:flutter/material.dart';

import 'bootstrap/app_bootstrap.dart';
import 'presentation/screens/backend_ready_screen.dart';

class MaintenanceReportsApp extends StatelessWidget {
  const MaintenanceReportsApp({
    super.key,
    required this.bootstrap,
  });

  final AppBootstrap bootstrap;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Informes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF184A45),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: BackendReadyScreen(
        reportService: bootstrap.reportService,
        config: bootstrap.config,
      ),
    );
  }
}

