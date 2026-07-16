# TecnoReport

Aplicación Android (Flutter) para que técnicos de campo registren informes de
mantenimiento de grupos electrógenos: formulario completo, fotos de antes/después,
firma de técnico y cliente, generación de PDF y sincronización a la nube.
Funciona offline-first: todo se guarda primero en SQLite local y se sincroniza
a Supabase cuando hay conexión.

## Funcionalidades

- Crear y editar informes de mantenimiento (datos del equipo, checklist de
  inspección, pruebas de funcionamiento, actividades, observaciones).
- Guardado local en SQLite, con auto-guardado de borrador mientras se edita.
- Reanudación del último informe en edición si la app se cierra a la mitad.
- Múltiples fotos por bloque ("antes del servicio" y "estado final").
- Captura de firma del técnico y del cliente.
- Generación de PDF local con membrete de la empresa; al generarlo se abre el
  selector nativo de Android ("Abrir con") para que el técnico elija con qué
  app verlo, guardarlo o compartirlo.
- Sincronización del JSON del informe con Supabase (autenticación anónima).
- Licencia remota / kill switch: activar, desactivar o poner fecha de
  vencimiento a la app entera desde Supabase, sin publicar una actualización.
- Respaldo local exportable (.zip) desde el panel de diagnóstico interno.

## Stack técnico

- Flutter / Dart
- SQLite (`sqflite`) para almacenamiento local
- Supabase (`supabase_flutter`) para sincronización remota y licencia
- `image_picker`, `pdf`, `path_provider`, `package_info_plus`, `archive`, `uuid`

## Requisitos

- Flutter SDK instalado y disponible en `PATH`
- Android SDK / Android Studio configurado
- Java 17 (el `jbr` que trae Android Studio funciona bien)
- Un dispositivo Android o emulador para probar

## Clonar el proyecto

```bash
git clone <URL_DEL_REPOSITORIO>
cd APP_CONTROL_INFORMES
flutter pub get
```

## Configuración local (Supabase)

La app lee la configuración de Supabase por variables de compilación, no por
archivos versionados en git.

1. Copia el ejemplo:

   ```bash
   cp config/app_config.example.json config/app_config.local.json
   ```

2. Completa los valores reales en `config/app_config.local.json`:

   | Variable | Qué es | Dónde se consigue |
   |---|---|---|
   | `SUPABASE_URL` | URL del proyecto | Supabase Dashboard → Project Settings → API → "Project URL" |
   | `SUPABASE_ANON_KEY` | Clave pública anónima | Supabase Dashboard → Project Settings → API → "anon public" |
   | `LOCAL_DATABASE_NAME` | Nombre del archivo SQLite en el dispositivo | Cualquier nombre, ej. `app_control_informes.db` |
   | `ENABLE_SUPABASE_SYNC` | Activa/desactiva la sincronización remota | `true` / `false` |
   | `ENABLE_SUPABASE_ANON_AUTH` | Activa el login anónimo antes de sincronizar | `true` / `false` |
   | `SUPABASE_REPORTS_TABLE` | Nombre de la tabla remota | `maintenance_reports` |

   `config/app_config.local.json` ya está en `.gitignore`: nunca se sube al
   repositorio.

3. **Notas de seguridad:**
   - `SUPABASE_ANON_KEY` sí puede ir dentro de la app (no es un secreto
     fuerte); la seguridad real está en las políticas RLS de las tablas.
   - `SUPABASE_SERVICE_ROLE_KEY` **nunca** debe ponerse en la app móvil.

## Preparar el backend en Supabase

Corre estos scripts una sola vez, en el SQL Editor de tu proyecto de Supabase:

1. [`supabase/setup_maintenance_reports.sql`](supabase/setup_maintenance_reports.sql)
   — crea la tabla `maintenance_reports` con RLS (cada usuario ve y edita solo
   sus propios informes).
2. [`supabase/setup_app_license.sql`](supabase/setup_app_license.sql) — crea la
   tabla `app_license` (el interruptor remoto) y la función `get_app_license()`
   que usa la app para revisar la licencia.
3. En **Authentication → Providers**, activa **Anonymous Sign-ins**. Sin esto
   la sincronización remota falla silenciosamente (la app sigue funcionando
   offline, pero nunca sube nada).

`supabase/maintenance_reports_schema.csv` es solo una referencia legible del
esquema de la tabla remota (no hace falta ejecutarlo).

## Licencia remota / kill switch

La licencia se revisa **solo al abrir la app** o al tocar **"Verificar de
nuevo"** en la pantalla de bloqueo — no hay revisión automática en segundo
plano mientras la app ya está abierta. Todos los cambios de abajo aplican sin
publicar ninguna actualización del APK.

Correr en el SQL Editor de Supabase:

**Bloquear la app ya (kill switch manual):**
```sql
update public.app_license
  set is_active = false,
      message = 'App suspendida. Contacte al proveedor.',
      updated_at = now()
where id = 'default';
```

**Reactivar la app:**
```sql
update public.app_license
  set is_active = true,
      valid_until = null,
      message = null,
      updated_at = now()
where id = 'default';
```

**Poner (o cambiar) una fecha de vencimiento** — la app se bloquea sola ese día
a las 23:59, sin que haya que volver a entrar. El mensaje que ven los técnicos
se genera automático ("La licencia venció el DD/MM/YYYY.") siempre que
`message` esté en `NULL`:
```sql
update public.app_license
  set valid_until = '2026-12-31 23:59:59-05',
      updated_at = now()
where id = 'default';
```

**Quitar la fecha de vencimiento** (vuelve a depender solo de `is_active`):
```sql
update public.app_license
  set valid_until = null,
      updated_at = now()
where id = 'default';
```

## Ejecutar en desarrollo

```bash
flutter run --dart-define-from-file=config/app_config.local.json
```

## Generar el APK de release

Requiere el keystore de firma (`.jks`) y `android/key.properties` (ninguno de
los dos vive en el repo — ver `.gitignore`). `key.properties` debe tener:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=upload-keystore.jks
```

con el `.jks` correspondiente puesto en `android/app/`. **No generes un
keystore nuevo si ya existe uno**: una actualización firmada con una clave
distinta a la de la versión instalada no se puede instalar sobre esta sin
antes desinstalar la app (y perder los informes locales no sincronizados).

```bash
flutter build apk --release --dart-define-from-file=config/app_config.local.json
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Estructura del proyecto

```text
android/                  proyecto nativo Android (manifest, firma, FileProvider)
assets/branding/           logo y branding
config/                    configuración local (ignorada por git salvo el ejemplo)
lib/src/
  application/             orquestación de flujos (crear/guardar/sincronizar informe)
  bootstrap/                arranque de la app (DB, Supabase, licencia)
  config/                   lectura de variables de compilación
  data/local/               SQLite (base de datos y repositorio)
  data/remote/              sincronización con Supabase
  domain/models/            modelos del dominio (MaintenanceReport, etc.)
  domain/repositories/       contratos de repositorio
  presentation/screens/      pantallas
  presentation/widgets/      widgets compartidos
  services/                  PDF, archivos, licencia, diagnóstico, validación
supabase/                  scripts SQL de configuración del backend
```

## Buenas prácticas antes de subir cambios

```bash
flutter analyze
git status
```

`git status` para confirmar que no se vaya a subir por accidente ningún
archivo local, credencial o build temporal.

## Mejoras futuras (no son bugs, la app funciona sin ellas)

- Probar el ciclo completo de licencia en un dispositivo Android físico (hoy
  solo se probó en emulador).
- Forzar `NOT NULL` en más columnas de `maintenance_reports` (hoy solo `id`,
  `uuid` y `owner_user_id` lo son) — protegería contra una edición manual
  incompleta desde el Table Editor de Supabase; no es explotable por la app.
- Revisión periódica de la licencia en segundo plano, si las sesiones largas
  (app abierta varias horas seguidas) se vuelven comunes.
- Mostrar el estado de la licencia (activa / vencimiento) en el panel de
  diagnóstico interno.
- Cifrar `license_cache.json` si la licencia se vuelve crítica para el
  negocio (hoy solo protege contra apagar internet o desinstalar; alguien con
  acceso root al dispositivo podría editarlo a mano).
- Modelo de bloqueo parcial por mantenimiento de pago (desactivar solo la
  sincronización remota en vez de bloquear toda la app) — pospuesto a
  propósito, no implementar todavía.
