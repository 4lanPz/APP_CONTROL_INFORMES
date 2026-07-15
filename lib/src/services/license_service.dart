import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Resultado de evaluar la licencia (kill switch remoto).
///
/// Si [locked] es `true`, la app debe mostrar la pantalla de bloqueo y no
/// permitir crear informes, generar PDF ni sincronizar.
class LicenseGate {
  const LicenseGate._({required this.locked, this.reason});

  const LicenseGate.allowed() : this._(locked: false);

  const LicenseGate.locked(String reason)
      : this._(locked: true, reason: reason);

  final bool locked;
  final String? reason;
}

/// Verifica el estado de la licencia contra Supabase y aplica un periodo de
/// gracia offline usando la hora del servidor (para que no se pueda burlar
/// simplemente apagando internet o cambiando el reloj del teléfono).
///
/// Fuente de verdad: fila `app_license` en Supabase, leída mediante la función
/// `get_app_license()` (SECURITY DEFINER). Ver `supabase/setup_app_license.sql`.
class LicenseService {
  LicenseService({required this.config});

  final AppConfig config;

  /// Cuánto puede funcionar la app sin lograr verificar la licencia.
  static const Duration graceDuration = Duration(days: 15);

  /// Timeout de la verificación remota para no colgar el arranque.
  static const Duration _networkTimeout = Duration(seconds: 6);

  /// Margen tolerado de retroceso de reloj antes de considerarlo manipulado.
  static const Duration _rollbackTolerance = Duration(minutes: 5);

  /// Evalúa la licencia. Nunca lanza: ante cualquier problema aplica el
  /// periodo de gracia con la última verificación conocida.
  Future<LicenseGate> evaluate() async {
    // Build sin Supabase configurado: no hay licencia que aplicar.
    if (!config.canUseSupabase) {
      return const LicenseGate.allowed();
    }

    try {
      final response = await Supabase.instance.client
          .rpc('get_app_license')
          .timeout(_networkTimeout);

      final row = _firstRow(response);
      if (row == null) {
        return _evaluateFromCache();
      }

      final active = row['is_active'] == true;
      final serverTime = DateTime.parse(row['server_time'] as String).toUtc();
      final deviceNow = DateTime.now().toUtc();

      await _saveCache(
        active: active,
        serverTime: serverTime,
        deviceNow: deviceNow,
      );

      if (active) {
        return const LicenseGate.allowed();
      }

      final message = (row['message'] as String?)?.trim();
      return LicenseGate.locked(
        message == null || message.isEmpty
            ? 'El proveedor desactivó la aplicación.'
            : message,
      );
    } catch (_) {
      // Sin conexión / error / timeout -> periodo de gracia.
      return _evaluateFromCache();
    }
  }

  Future<LicenseGate> _evaluateFromCache() async {
    final cache = await _readCache();

    // Nunca se pudo verificar (p. ej. primer arranque sin internet). No
    // dejamos inservible una instalación recién hecha: se permite hasta que
    // haya al menos una verificación exitosa, momento en que ya aplica gracia.
    if (cache == null) {
      return const LicenseGate.allowed();
    }

    if (!cache.active) {
      return const LicenseGate.locked(
        'El proveedor desactivó la aplicación.',
      );
    }

    final deviceNow = DateTime.now().toUtc();

    // Anti-trampa: reloj movido hacia atrás respecto al máximo visto.
    if (deviceNow
        .isBefore(cache.highWaterDevice.subtract(_rollbackTolerance))) {
      return const LicenseGate.locked(
        'No se pudo verificar la licencia (reloj alterado). '
        'Conéctate a internet para revalidar.',
      );
    }

    final elapsed = deviceNow.difference(cache.deviceTime);
    if (elapsed.isNegative || elapsed > graceDuration) {
      return const LicenseGate.locked(
        'La app lleva demasiado tiempo sin verificar la licencia. '
        'Conéctate a internet para revalidar.',
      );
    }

    return const LicenseGate.allowed();
  }

  Map<String, dynamic>? _firstRow(dynamic response) {
    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'license_cache.json'));
  }

  Future<_LicenseCache?> _readCache() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) {
        return null;
      }
      final json = jsonDecode(await file.readAsString());
      if (json is Map<String, dynamic>) {
        return _LicenseCache.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache({
    required bool active,
    required DateTime serverTime,
    required DateTime deviceNow,
  }) async {
    try {
      final previous = await _readCache();
      final highWater = previous == null
          ? deviceNow
          : (deviceNow.isAfter(previous.highWaterDevice)
              ? deviceNow
              : previous.highWaterDevice);

      final cache = _LicenseCache(
        active: active,
        serverTime: serverTime,
        deviceTime: deviceNow,
        highWaterDevice: highWater,
      );

      final file = await _cacheFile();
      await file.writeAsString(jsonEncode(cache.toJson()));
    } catch (_) {
      // Si no se puede escribir el caché no bloqueamos por eso.
    }
  }
}

/// Última verificación de licencia guardada localmente.
class _LicenseCache {
  _LicenseCache({
    required this.active,
    required this.serverTime,
    required this.deviceTime,
    required this.highWaterDevice,
  });

  final bool active;

  /// Hora del servidor en la última verificación exitosa.
  final DateTime serverTime;

  /// Hora del dispositivo en la última verificación exitosa.
  final DateTime deviceTime;

  /// Máxima hora de dispositivo vista (para detectar retroceso de reloj).
  final DateTime highWaterDevice;

  Map<String, dynamic> toJson() => {
        'active': active,
        'serverTime': serverTime.toUtc().toIso8601String(),
        'deviceTime': deviceTime.toUtc().toIso8601String(),
        'highWaterDevice': highWaterDevice.toUtc().toIso8601String(),
      };

  static _LicenseCache? fromJson(Map<String, dynamic> json) {
    try {
      return _LicenseCache(
        active: json['active'] == true,
        serverTime: DateTime.parse(json['serverTime'] as String).toUtc(),
        deviceTime: DateTime.parse(json['deviceTime'] as String).toUtc(),
        highWaterDevice:
            DateTime.parse(json['highWaterDevice'] as String).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }
}
