# Backend Setup

## Qué se configura aquí

La app usa dos capas distintas:

- SQLite local para guardar los informes en el dispositivo
- Supabase para sincronizar el JSON de los informes a la nube

SQLite en este proyecto no usa usuario, contraseña ni servidor. Es solo un archivo local dentro del dispositivo. Lo que sí parametrizamos es el nombre del archivo y los valores de Supabase.

## Variables disponibles

La app lee estas variables en tiempo de compilación:

- `LOCAL_DATABASE_NAME`
- `ENABLE_SUPABASE_SYNC`
- `ENABLE_SUPABASE_ANON_AUTH`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_REPORTS_TABLE`

Ejemplo base en:

`config/app_config.example.json`

## Archivo local recomendado

Crea un archivo local, por ejemplo:

`config/app_config.local.json`

Ese archivo ya está ignorado por git.

Ejemplo:

```json
{
  "LOCAL_DATABASE_NAME": "app_control_informes.db",
  "ENABLE_SUPABASE_SYNC": "true",
  "ENABLE_SUPABASE_ANON_AUTH": "true",
  "SUPABASE_URL": "https://tu-proyecto.supabase.co",
  "SUPABASE_ANON_KEY": "tu-anon-key",
  "SUPABASE_REPORTS_TABLE": "maintenance_reports"
}
```

## Importante sobre la key de Supabase

- `SUPABASE_ANON_KEY`: sí puede ir dentro de la app
- `SUPABASE_SERVICE_ROLE_KEY`: no debe ir nunca dentro de la app móvil

La `anon key` no se trata como secreto fuerte. La seguridad real debe estar en las políticas RLS de Supabase.

## Requisito recomendado para este proyecto

Activa autenticación anónima en Supabase Auth.

La app ya quedó preparada para exigir un usuario autenticado antes de sincronizar. Así cada informe remoto queda asociado a `auth.uid()` y no se crean filas huérfanas.

## Crear la tabla en Supabase

Ejecuta el SQL de:

`supabase/001_initial_schema.sql`

Ese esquema ya deja la tabla preparada con RLS para que cada usuario solo vea y actualice sus propios informes.

## Correr la app con variables

Opción recomendada:

```bash
flutter run --dart-define-from-file=config/app_config.local.json
```

Opción manual:

```bash
flutter run ^
  --dart-define=LOCAL_DATABASE_NAME=app_control_informes.db ^
  --dart-define=ENABLE_SUPABASE_SYNC=true ^
  --dart-define=ENABLE_SUPABASE_ANON_AUTH=true ^
  --dart-define=SUPABASE_URL=TU_SUPABASE_URL ^
  --dart-define=SUPABASE_ANON_KEY=TU_SUPABASE_ANON_KEY ^
  --dart-define=SUPABASE_REPORTS_TABLE=maintenance_reports
```

Para release:

```bash
flutter build apk --release --dart-define-from-file=config/app_config.local.json
```

## Qué ya está implementado

- persistencia local con SQLite
- nombre del archivo SQLite configurable por variable
- sincronización JSON con Supabase
- autenticación anónima opcional
- validación del formulario
- copia local de fotos
- generación local de PDF
- captura de firmas
- guardado del PDF en Descargas

## Qué falta antes de producción

- probar sincronización real con tu proyecto de Supabase
- decidir si después se subirán fotos o solo JSON
- definir respaldo/recuperación de informes por usuario
