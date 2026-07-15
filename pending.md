# Pendientes

Nada de lo que hay acá es un bug ni algo roto — son mejoras opcionales para
más adelante. La app ya está en condiciones de presentarse como versión
final; esto es la lista de "cosas que podemos pulir después".

## Ya resuelto (para contexto, no requiere acción)

Borrador/recuperación, panel de estado (con chequeos reales de DB local y
conectividad Supabase), licencia/kill switch con vencimiento por fecha
(`valid_until`), firma de release con keystore propio (con backup ya hecho
por fuera del repo), limpieza de código muerto, eliminar informe, borrado de
fotos huérfanas al quitarlas del formulario, sincronización automática al
abrir la app y al guardar un informe, y saneo de rutas en el canal nativo de
Descargas. Instrucciones completas de cómo bloquear/desbloquear la app y
cómo generar/mandar una actualización del APK: ver `MANUAL_INTERNO.md`
(no está en git).

## 1. Probar el ciclo de licencia en el teléfono

Todavía no se probó en un dispositivo real:

- Con internet → abre normal (queda activa).
- `is_active = false` en Supabase → reabrir / "Verificar de nuevo" → bloqueada.
- `is_active = true` → "Verificar de nuevo" → vuelve a la app.
- Poner `valid_until` en el pasado → reabrir → bloqueada con mensaje
  automático de vencimiento.
- Confirmar que "Anonymous Sign-ins" esté activo en Supabase (Authentication);
  sin eso la sincronización remota falla.

## 2. `NOT NULL` en columnas de `maintenance_reports`

Hoy solo `id`, `uuid` y `owner_user_id` son obligatorias en la tabla remota;
el resto (`report_json`, `service_date`, `location`, etc.) permite `NULL`.
No es urgente: la app siempre manda el informe completo, así que en la
práctica nunca va a llegar una fila incompleta por su culpa. Solo protegería
contra una edición manual incompleta desde el Table Editor de Supabase. Si
se quiere aplicar, usar el mismo método que con `owner_user_id`: contar
cuántas filas tienen `NULL` en cada columna antes de forzar la restricción.

## 3. Reverificación periódica de la licencia

Hoy la licencia se revisa solo al abrir la app o al tocar "Verificar de
nuevo" en `LockedScreen`. Si en el futuro las sesiones largas (app abierta
varias horas seguidas) se vuelven comunes, valdría la pena agregar una
revisión periódica en segundo plano.

## 4. Mostrar el estado de la licencia en el panel de estado

`AppStatusScreen` no muestra hoy si la licencia está activa, en período de
gracia, ni la fecha de vencimiento (`valid_until`) si hay una configurada.
Sería un dato útil para diagnóstico en soporte.

## 5. Futuro modelo de bloqueo por mantenimiento de datos en la nube

Explícitamente pospuesto — no implementar todavía. Cuando llegue el momento:
en vez de bloquear toda la app si no se paga, la idea es que solo se
desactive la sincronización remota (guardado local y PDF siguen funcionando
igual). Requiere un gate separado del `LicenseGate` actual, que hoy bloquea
todo con `LockedScreen`.

## 6. Correo del segundo desarrollador sin configurar

En `DeveloperInfoScreen`, el perfil de "Ingrith-R2" tiene `emailAddress`
vacío. Se deja así a propósito hasta terminar el desarrollo.

## 7. Caché de licencia sin cifrar

`license_cache.json` (`LicenseService`) se guarda en texto plano en el
almacenamiento de la app. Alguien con acceso root al dispositivo podría
editarlo a mano (`active: true`) para burlar el kill switch durante el
período de gracia. No es explotable de forma remota ni por un usuario
normal sin root; si en algún momento la licencia se vuelve crítica para el
negocio, valdría la pena cifrar el archivo o firmarlo con una clave que no
viva en el propio dispositivo.
