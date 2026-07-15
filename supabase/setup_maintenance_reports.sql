-- ============================================================
--  TecnoReport · Configuración de Supabase (Opción A)
--  Cada usuario/dispositivo solo ve y edita SUS propios informes.
--  Pegar todo esto en:  Supabase Dashboard > SQL Editor > New query > Run
-- ============================================================

-- 1) Tabla de informes -----------------------------------------------------
--    Los nombres de columnas coinciden EXACTAMENTE con lo que envía la app
--    (ver supabase_sync_service.dart -> _toRemoteRow).
create table if not exists public.maintenance_reports (
  uuid              text primary key,
  owner_user_id     uuid not null references auth.users (id) on delete cascade,
  service_date      date,
  maintenance_type  text,
  location          text,
  technician_name   text,
  sync_status       text,
  report_json       jsonb not null,
  created_at        timestamptz,
  updated_at        timestamptz,
  synced_at         timestamptz
);

-- Índice para listar rápido por dueño.
create index if not exists maintenance_reports_owner_idx
  on public.maintenance_reports (owner_user_id);

-- 2) Activar Row Level Security (esto es lo que REALMENTE protege) ----------
alter table public.maintenance_reports enable row level security;

-- 3) Políticas: un usuario solo toca sus propias filas ---------------------
--    (Los usuarios anónimos de Supabase igual tienen el rol 'authenticated'.)

drop policy if exists "own_select" on public.maintenance_reports;
create policy "own_select"
  on public.maintenance_reports
  for select
  to authenticated
  using (owner_user_id = auth.uid());

drop policy if exists "own_insert" on public.maintenance_reports;
create policy "own_insert"
  on public.maintenance_reports
  for insert
  to authenticated
  with check (owner_user_id = auth.uid());

drop policy if exists "own_update" on public.maintenance_reports;
create policy "own_update"
  on public.maintenance_reports
  for update
  to authenticated
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

drop policy if exists "own_delete" on public.maintenance_reports;
create policy "own_delete"
  on public.maintenance_reports
  for delete
  to authenticated
  using (owner_user_id = auth.uid());

-- ============================================================
--  Nota: NO se crea ninguna política para el rol 'anon' sin sesión,
--  así una anon key robada, sin iniciar sesión, no lee nada.
-- ============================================================
