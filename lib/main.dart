import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.create();
  runApp(MaintenanceReportsApp(bootstrap: bootstrap));
}

