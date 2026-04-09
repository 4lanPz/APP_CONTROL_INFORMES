# Backend Setup

## 1. Instalar Flutter

Necesitas tener `flutter` y `dart` disponibles en tu PATH.

## 2. Generar archivos nativos de Flutter

Este repositorio ya tiene la base de `lib/` y `pubspec.yaml`, pero como en este entorno no estaba instalado Flutter, aun no se generaron las carpetas nativas.

Cuando ya tengas Flutter instalado, ejecuta:

```bash
flutter create --platforms=android .
```

## 3. Descargar dependencias

```bash
flutter pub get
```

## 4. Crear tabla en Supabase

Ejecuta el SQL de:

`supabase/001_initial_schema.sql`

Si quieres mantener la app sin login visible para el usuario, habilita autenticacion anonima en Supabase Auth.

## 5. Variables para correr la app

Ejemplo:

```bash
flutter run ^
  --dart-define=ENABLE_SUPABASE_SYNC=true ^
  --dart-define=ENABLE_SUPABASE_ANON_AUTH=true ^
  --dart-define=SUPABASE_URL=TU_SUPABASE_URL ^
  --dart-define=SUPABASE_ANON_KEY=TU_SUPABASE_ANON_KEY ^
  --dart-define=SUPABASE_REPORTS_TABLE=maintenance_reports
```

## 6. Que ya esta implementado

- Modelo completo de informe
- Persistencia local con SQLite
- Repositorio local offline-first
- Validacion del formulario
- Copia local de fotos
- Generacion local de PDF
- Sincronizacion JSON con Supabase
- Pantalla minima para probar backend

## 7. Siguiente paso recomendado

Conectar una plantilla visual nueva al servicio principal:

`lib/src/application/report_workflow_service.dart`

Ese archivo ya concentra el flujo que luego consumira el frontend.
