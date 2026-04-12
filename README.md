# TecnoReport DEBUG

Aplicación Android desarrollada en Flutter para registrar informes de mantenimiento de grupos electrógenos, trabajar sin conexión, generar PDF locales y sincronizar el JSON del informe con Supabase cuando la configuración remota está habilitada.

## Estado del proyecto

El proyecto está en etapa de validación previa a entrega. Por eso se mantienen visibles las marcas `DEBUG` en la app y en parte del flujo documental.

Funcionalidades ya implementadas:

- creación y edición de informes de mantenimiento
- guardado local en SQLite
- auto guardado mientras se edita el formulario
- reanudación del último informe en edición si Android reinicia la app
- múltiples fotos por bloque (`antes` y `estado final`)
- captura de firma de técnico y cliente
- generación de PDF local
- guardado del PDF en `Descargas/Informes Generados`
- sincronización del JSON del informe con Supabase
- modo visual `DEBUG` en la app

## Stack técnico

- Flutter
- Dart
- SQLite con `sqflite`
- Supabase con `supabase_flutter`
- `image_picker`
- `pdf`
- `printing`
- `url_launcher`

## Requisitos

- Flutter instalado y disponible en `PATH`
- Android Studio o Android SDK configurado
- Java 17, preferiblemente el `jbr` de Android Studio
- dispositivo Android o emulador para pruebas

## Clonar el proyecto

```bash
git clone <TU_URL_DEL_REPOSITORIO>
cd APP_CONTROL_INFORMES
```

## Configuración local

Este proyecto usa variables de compilación para la configuración local y remota.

1. Crea un archivo local a partir del ejemplo:

```bash
copy config\app_config.example.json config\app_config.local.json
```

2. Completa tus valores reales en `config/app_config.local.json`.

Variables principales:

- `LOCAL_DATABASE_NAME`
- `ENABLE_SUPABASE_SYNC`
- `ENABLE_SUPABASE_ANON_AUTH`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_REPORTS_TABLE`

Documentación ampliada:

- [BACKEND_SETUP.md](BACKEND_SETUP.md)

## Importante sobre credenciales y GitHub

No debes subir al repositorio:

- `config/app_config.local.json`
- claves privadas de firma Android
- archivos de entorno personales
- caches de build o archivos del IDE

El proyecto ya ignora por `.gitignore`:

- `config/*.local.json`
- `.idea/`
- `*.iml`
- `.dart_tool/`
- `build/`

Notas de seguridad:

- `SUPABASE_ANON_KEY` puede vivir dentro de la app, pero no debe tratarse como secreto fuerte
- la seguridad real está en las políticas RLS de Supabase
- nunca pongas `SUPABASE_SERVICE_ROLE_KEY` dentro de la app móvil

## Ejecutar en desarrollo

```bash
flutter pub get
flutter run --dart-define-from-file=config/app_config.local.json
```

## Generar APK release

```bash
flutter build apk --release --dart-define-from-file=config/app_config.local.json
```

APK generada en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Estructura del proyecto

```text
assets/
  branding/
  templates/
android/
config/
lib/
  src/
    application/
    bootstrap/
    config/
    data/
      local/
      remote/
    domain/
      models/
      repositories/
    presentation/
      screens/
      widgets/
    services/
supabase/
```

## Assets importantes

- logo de la app: `assets/branding/TecnoReport.png`
- plantilla PDF base: `assets/templates/Formulario_base.pdf`

## Flujo actual

1. Crear o editar un informe.
2. Completar datos generales, checklist, pruebas y observaciones.
3. Adjuntar fotos del antes y del estado final.
4. Capturar firma del técnico y del cliente.
5. Guardar el informe localmente.
6. Generar PDF o sincronizar el JSON si Supabase está habilitado.

## Supabase

La app sincroniza una fila en la tabla `maintenance_reports` y guarda el informe completo en `report_json`.

Archivo de referencia para crear la tabla y RLS:

- [001_initial_schema.sql](supabase/001_initial_schema.sql)

## Estado release actual

Se mantiene intencionalmente:

- nombre visible `TecnoReport DEBUG`
- badge visual `DEBUG`
- firma debug para la APK release de pruebas

Eso permite seguir probando antes del cierre comercial. Cuando llegue el momento de entrega final, conviene cambiar la firma Android por una release key propia.

## Buenas prácticas al actualizar

Antes de subir cambios al repositorio:

```bash
flutter analyze
```

Y revisa siempre:

```bash
git status
```

para confirmar que no se estén yendo archivos locales, credenciales o builds temporales.

## Pendientes naturales para siguientes etapas

- flujo de backup/exportación local de informes
- estrategia de restauración/importación
- posible subida futura de fotos a almacenamiento remoto
- firma release definitiva
- retiro del modo `DEBUG` cuando corresponda

