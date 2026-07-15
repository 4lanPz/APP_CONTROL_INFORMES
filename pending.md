# Pendientes

Tareas identificadas durante la limpieza de código. No son bugs bloqueantes, pero
conviene resolverlas antes del cierre comercial.

## 1. Estado `draft` (borrador) — IMPLEMENTADO

**Estado actual:** ✅ hecho.

- Si la app se cierra/crashea con un formulario a medias, al reabrir la app el
  formulario reaparece (vía `EditingSessionService` + auto-guardado).
- El auto-guardado (`_persistDraft`) ahora guarda con `SyncStatus.draft`
  (`saveReport(report, asDraft: true)`), así que un formulario incompleto **NO se
  sube a la nube**.
- Solo el guardado explícito exitoso ("Guardar informe", que valida todos los
  campos) promueve el informe a `SyncStatus.pendingSync`.
- `syncPendingReports()` sigue tomando solo `pendingSync` (los `draft` quedan fuera).
- En el home, los informes en `draft` aparecen en un grupo "Recuperados" con el
  título prefijado `recuperado_<nombre>`.

**Comportamiento resultante (según el equipo):**

1. Formulario incompleto / interrumpido → `draft` → NO se sincroniza, se ve como
   "recuperado_...".
2. Formulario completo y sin internet → `pendingSync` → se guarda local, se sube luego.
3. Formulario completo y con internet → `pendingSync` → al sincronizar pasa a `synced`.

**Pendiente menor / a vigilar:**

- Editar un informe ya `synced`/`pendingSync` y salir sin guardar lo deja como
  `draft` (por el auto-guardado). Es intencional (tiene cambios sin confirmar),
  pero conviene confirmarlo en pruebas reales por si resulta confuso.

## 2. Indicador de estado de base — RESUELTO

**Estado actual:** ✅ movido fuera del home.

- Se quitó de la pantalla principal la tarjeta "Estado general" (mostraba un
  "Correcto" fijo, sin comprobar nada real).
- El estado real ahora vive en el **panel de estado de la app** (icono de
  engranaje del home → `AppStatusScreen`): base local (existe + tamaño), base
  Supabase (sync activo, proyecto, sesión), informes (pendientes/enviados/error)
  y UUID del usuario.

**Pendiente menor:**

- El estado de "base local" se infiere de si el archivo `.db` existe. Si se quiere
  un chequeo más fuerte, exponer desde `AppDatabase` un flag real de "abrió
  correctamente" y mostrarlo en `AppStatusScreen`.

## 3. Licencia / Kill switch remoto — IMPLEMENTADO (falta configurar Supabase)

**Estado actual:** ✅ código hecho. ⏳ falta correr el SQL en Supabase.

- Interruptor manual: fila única `app_license` en Supabase (`is_active` true/false).
- Periodo de gracia offline: **15 días** desde la última verificación exitosa,
  usando la hora del servidor + anti-trampa de reloj
  (`LicenseService.graceDuration` en `lib/src/services/license_service.dart`).
- Cuando está bloqueada: se muestra `LockedScreen` (único punto de entrada), así
  que no se puede crear informes, generar PDF ni sincronizar. Tiene botón
  "Verificar de nuevo".
- Enganche único en `lib/src/app.dart` (`_LicenseGateView`).
- Se quitó el badge "DEBUG" (`DraftAppBarTitle.showDraftBadge = false`) y el
  título de la app pasó a `TecnoReport` (sin "DEBUG").

**Falta hacer:**

1. **Correr el SQL** `supabase/setup_app_license.sql` en el dashboard de Supabase
   (crea la tabla `app_license`, RLS cerrado y la función `get_app_license()`).
   Sin esto, la verificación remota falla y la app queda en periodo de gracia.
2. **Probar el ciclo completo** en el teléfono:
   - Con internet → abre normal (queda activa).
   - `is_active = false` en Supabase → reabrir / "Verificar de nuevo" → bloqueada.
   - `is_active = true` → "Verificar de nuevo" → vuelve a la app.
3. **Confirmar la sincronización real** de informes (el error `errno = 7` fue
   falta de internet en el teléfono, no del APK): activar "Anonymous Sign-ins"
   en Supabase (Authentication) y correr `supabase/setup_maintenance_reports.sql`
   con las políticas RLS (Opción A: cada dispositivo ve solo lo suyo).

**Mejoras opcionales a futuro:**

- Reverificar la licencia periódicamente (ahora solo al arrancar y con el botón).
- Mostrar en `AppStatusScreen` el estado de la licencia (activa / gracia / días
  restantes) para diagnóstico.
- Si se quiere bloqueo por vencimiento (fecha) además del interruptor manual,
  agregar `valid_until` a `app_license` y a la función `get_app_license()`.
