# App Movil de Informes de Mantenimiento

App Android hecha en Flutter para registrar informes de mantenimiento de grupos electrogenos, trabajar sin internet y generar PDF locales a partir del formulario.

## Estado actual

El proyecto ya tiene una base funcional usable para pruebas reales en Android.

### Cumplido hasta este punto

- formulario completo de informe de mantenimiento
- guardado local de informes en SQLite
- edicion de informes existentes
- listado de informes guardados con estado de sincronizacion
- seleccion de 2 fotos desde la galeria:
  - foto antes
  - foto despues
- copiado local de fotos para mantenerlas bajo control de la app
- generacion local de PDF
- guardado del PDF en `Descargas/Informes Generados` en Android
- preparacion para sincronizacion futura con Supabase
- estados de sincronizacion:
  - `pending_sync`
  - `synced`
  - `sync_error`
- marca visual de `BORRADOR` en la app
- marca de agua `BORRADOR` en el PDF
- auto guardado del formulario mientras se edita
- reanudacion del ultimo informe en edicion si Android reinicia la app al volver del segundo plano

### Pendiente

- build APK estable desde esta maquina sin problemas de entorno
- flujo final de version pagada para quitar el modo borrador
- mejora de restauracion total del estado visual si se quiere comportamiento mas cercano a apps como WhatsApp
- compartir PDF desde la app
- captura de foto con camara dentro de la app
- firma digital o captura de firma
- autenticacion de usuarios
- panel web o backoffice

## Cambios recientes

### PDF

- el PDF ahora se guarda en la carpeta publica `Downloads/Informes Generados`
- se agrego marca de agua `BORRADOR`
- el texto de marca de agua se puede quitar facil despues

Archivo principal:
- `lib/src/services/report_pdf_service.dart`

### Formulario

- el formulario ahora se auto guarda en segundo plano
- si Android mata la app, al volver se intenta reabrir el ultimo informe en edicion
- ya no se muestra debajo de cada foto la ruta local del archivo

Archivos principales:
- `lib/src/presentation/screens/report_form_screen.dart`
- `lib/src/services/editing_session_service.dart`
- `lib/src/presentation/screens/reports_home_screen.dart`

### App en modo borrador

- se agrego una marca `BORRADOR` en los titulos principales de la app
- el nombre general de la app tambien refleja que esta en modo borrador

Archivo principal:
- `lib/src/presentation/widgets/draft_app_bar_title.dart`

## Flujo actual

1. El usuario abre la app.
2. Crea un informe nuevo o edita uno existente.
3. Llena el formulario.
4. Adjunta 2 fotos desde la galeria.
5. El formulario se va guardando localmente mientras se edita.
6. Si la app pasa a segundo plano y Android la reinicia, al volver intenta abrir otra vez el informe que estaba en edicion.
7. Al guardar, el informe queda persistido localmente con estado `pending_sync`.
8. Cuando el usuario lo necesite, puede generar el PDF.
9. El PDF se guarda en `Descargas/Informes Generados`.

## Reglas funcionales ya aplicadas

- todos los campos del formulario son obligatorios por ahora
- solo se usan 2 fotos por informe
- las fotos se seleccionan desde la galeria
- las fotos no se suben a Supabase en esta version
- el PDF no se guarda en ninguna base de datos online
- todo informe editado vuelve a `pending_sync`
- cada informe se identifica por UUID

## Stack actual

- Flutter
- SQLite con `sqflite`
- `path_provider`
- `image_picker`
- `pdf`
- `printing`
- `supabase_flutter`

## Estructura principal

- `lib/src/presentation`
  - pantallas y widgets
- `lib/src/application`
  - flujo de trabajo del informe
- `lib/src/data/local`
  - base de datos SQLite y repositorio local
- `lib/src/services`
  - PDF, archivos, validacion y sesion de edicion
- `android/`
  - integracion nativa Android para guardar PDF en Descargas

## Modo borrador

Actualmente el proyecto esta en modo borrador/demostracion.

### Donde se desactiva despues

- marca de agua PDF:
  - `lib/src/services/report_pdf_service.dart`
  - cambiar `_showDraftWatermark` a `false`
- marca visual en la app:
  - `lib/src/presentation/widgets/draft_app_bar_title.dart`
  - cambiar `showDraftBadge` a `false`

## Nota sobre pruebas y compilacion

En esta maquina hubo problemas de entorno para compilar APK por una mezcla de:

- proyecto en `E:`
- caches de Gradle y Pub en `C:`
- Java por defecto en version 8
- locks viejos de Gradle

Eso no es un problema del codigo funcional de la app, sino del entorno local de compilacion.

## Objetivo de la siguiente etapa

- estabilizar el entorno de build
- generar APK de prueba
- validar en telefono el flujo completo:
  - llenar formulario
  - minimizar app
  - retomar informe
  - generar PDF
  - confirmar guardado en Descargas
