-- ============================================================
--  TecnoReport · Licencia / Kill switch remoto
--  Pegar en:  Supabase Dashboard > SQL Editor > New query > Run
--  Para BLOQUEAR, REACTIVAR o ponerle fecha de vencimiento, ver el final.
-- ============================================================

-- 1) Tabla con una sola fila (el interruptor) -----------------------------
create table if not exists public.app_license (
  id          text primary key default 'default',
  is_active   boolean not null default true,
  message     text,                       -- texto opcional que ve el usuario
  valid_until timestamptz,                -- NULL = sin fecha de vencimiento
  updated_at  timestamptz not null default now()
);

-- Fila única inicial (activa, sin vencimiento).
insert into public.app_license (id, is_active, message, valid_until)
values ('default', true, null, null)
on conflict (id) do nothing;

-- 2) RLS: nadie con la anon key puede leer/escribir la tabla directamente --
alter table public.app_license enable row level security;
-- (No se crea ninguna política -> la tabla queda inaccesible con la anon key.)

-- 3) Función segura que la app SÍ puede llamar ----------------------------
--    Devuelve el estado + la hora del servidor (para el periodo de gracia
--    offline) + la fecha de vencimiento (si hay). Es SECURITY DEFINER, así
--    que puede leer la tabla aunque el RLS la bloquee para el cliente.
--
--    is_active combina el interruptor manual Y la fecha de vencimiento: si
--    cualquiera de los dos "dice que no", la app se bloquea. Si no le pones
--    mensaje propio, el vencimiento por fecha genera uno automático.
create or replace function public.get_app_license()
returns table (
  is_active boolean,
  message text,
  server_time timestamptz,
  valid_until timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    (l.is_active and (l.valid_until is null or now() < l.valid_until)) as is_active,
    coalesce(
      l.message,
      case
        when l.valid_until is not null and now() >= l.valid_until
          then 'La licencia venció el ' || to_char(l.valid_until, 'DD/MM/YYYY') || '.'
        else null
      end
    ) as message,
    now() as server_time,
    l.valid_until
  from public.app_license l
  where l.id = 'default'
  limit 1;
$$;

grant execute on function public.get_app_license() to anon, authenticated;

-- ============================================================
--  USO DIARIO (desde el SQL Editor o el Table Editor):
--
--  Bloquear la app YA (kill switch manual):
--     update public.app_license
--       set is_active = false,
--           message = 'App suspendida. Contacte al proveedor.',
--           updated_at = now()
--     where id = 'default';
--
--  Reactivar la app:
--     update public.app_license
--       set is_active = true,
--           message = null,
--           updated_at = now()
--     where id = 'default';
--
--  Ponerle fecha de vencimiento (se bloquea sola ese día a las 23:59,
--  sin que tengas que volver a entrar aquí ese día). El mensaje se genera
--  solo si no le pones uno propio:
--     update public.app_license
--       set valid_until = '2026-12-31 23:59:59-05',
--           updated_at = now()
--     where id = 'default';
--
--  Quitar la fecha de vencimiento (vuelve a depender solo de is_active):
--     update public.app_license
--       set valid_until = null,
--           updated_at = now()
--     where id = 'default';
--
--  (También puedes editar la fila a mano en Table Editor > app_license.)
--  El cambio aplica al reabrir la app o al tocar "Verificar de nuevo".
-- ============================================================
