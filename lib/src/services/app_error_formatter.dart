import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorFormatter {
  const AppErrorFormatter._();

  static String format(
    Object error, {
    String fallback = 'Ocurrió un error inesperado.',
  }) {
    if (error is AuthException) {
      final message = error.message.trim();
      return message.isEmpty
          ? 'No se pudo autenticar con el servicio remoto.'
          : message;
    }

    if (error is PostgrestException) {
      final message = error.message.trim();
      return message.isEmpty
          ? 'Supabase rechazó la operación solicitada.'
          : message;
    }

    if (error is StorageException) {
      final message = error.message.trim();
      return message.isEmpty
          ? 'No se pudo completar la operación de almacenamiento.'
          : message;
    }

    if (error is SocketException) {
      return 'No hay conexión a internet o el servidor no responde.';
    }

    if (error is DatabaseException) {
      return 'No se pudo acceder a la base de datos local.';
    }

    if (error is FileSystemException) {
      final message = error.message.trim();
      return message.isEmpty ? fallback : message;
    }

    if (error is PlatformException) {
      final message = error.message?.trim() ?? '';
      return message.isEmpty ? fallback : message;
    }

    if (error is MissingPluginException) {
      return 'Esta función no está disponible en este dispositivo.';
    }

    if (error is StateError) {
      final message = error.message.trim();
      return message.isEmpty ? fallback : message;
    }

    final rawMessage = error.toString().trim();
    if (rawMessage.isEmpty) {
      return fallback;
    }

    const prefixes = <String>[
      'Exception: ',
      'Bad state: ',
      'StateError: ',
    ];

    for (final prefix in prefixes) {
      if (rawMessage.startsWith(prefix)) {
        return rawMessage.substring(prefix.length).trim();
      }
    }

    return rawMessage;
  }

  static String withPrefix(
    String prefix,
    Object error, {
    String fallback = 'Ocurrió un error inesperado.',
  }) {
    return '$prefix: ${format(error, fallback: fallback)}';
  }
}
