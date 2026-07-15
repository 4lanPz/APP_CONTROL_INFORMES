-- ============================================================
--  TecnoReport · Licencia / Kill switch remoto
--  Pegar en:  Supabase Dashboard > SQL Editor > New query > Run
--  Para BLOQUEAR o REACTIVAR la app luego, ver el final del archivo.
-- ============================================================

-- 1) Tabla con una sola fila (el interruptor) -----------------------------
create table if not exists public.app_license (
  id          text primary key default 'default',
  is_active   boolean not null default true,
  message     text,                       -- texto opcional que ve el usuario
  updated_at  timestamptz not null default now()
);

-- Fila única inicial (activa).
insert into public.app_license (id, is_active, message)
values ('default', true, null)
on conflict (id) do nothing;

-- 2) RLS: nadie con la anon key puede leer/escribir la tabla directamente --
alter table public.app_license enable row level security;
-- (No se crea ninguna política -> la tabla queda inaccesible con la anon key.)

-- 3) Función segura que la app SÍ puede llamar ----------------------------
--    Devuelve solo el estado + la hora del servidor (para el periodo de
--    gracia offline). Es SECURITY DEFINER, así que puede leer la tabla
--    aunque el RLS la bloquee para el cliente.
create or replace function public.get_app_license()
returns table (is_active boolean, message text, server_time timestamptz)
language sql
security definer
set search_path = public
as $$
  select l.is_active, l.message, now() as server_time
  from public.app_license l
  where l.id = 'default'
  limit 1;
$$;

grant execute on function public.get_app_license() to anon, authenticated;

-- ============================================================
--  USO DIARIO (desde el SQL Editor o el Table Editor):
--
--  Bloquear la app (kill switch):
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
--  (También puedes editar la fila a mano en Table Editor > app_license.)
--  El cambio aplica al reabrir la app o al tocar "Verificar de nuevo".
-- ============================================================
