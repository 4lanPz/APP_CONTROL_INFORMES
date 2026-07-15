/// Helpers de formateo de fechas usados en toda la app.
///
/// Antes estas funciones estaban copiadas en varios archivos (modelo,
/// repositorio, sync, PDF y pantallas). Se centralizan aquí para tener una sola
/// fuente de verdad.
library;

/// Formatea una fecha como `yyyy-MM-dd`.
///
/// Uso interno / técnico: persistencia en base de datos, JSON y APIs.
String formatIsoDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

/// Formatea una fecha como `dd/MM/yyyy`.
///
/// Uso visual: lo que ve el usuario en pantallas y en el PDF.
String formatDisplayDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
