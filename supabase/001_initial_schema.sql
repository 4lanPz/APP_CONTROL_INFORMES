create extension if not exists pgcrypto;

create table if not exists public.maintenance_reports (
  id uuid primary key default gen_random_uuid(),
  uuid text not null unique,
  owner_user_id uuid not null references auth.users (id) on delete cascade,
  service_date date not null,
  maintenance_type text not null,
  location text not null default '',
  technician_name text not null default '',
  sync_status text not null default 'pending_sync',
  report_json jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  synced_at timestamptz
);

create index if not exists idx_maintenance_reports_service_date
  on public.maintenance_reports (service_date desc);

create index if not exists idx_maintenance_reports_sync_status
  on public.maintenance_reports (sync_status);

alter table public.maintenance_reports enable row level security;

create policy "maintenance_reports_select_own"
  on public.maintenance_reports
  for select
  using (
    auth.uid() = owner_user_id
  );

create policy "maintenance_reports_insert_own"
  on public.maintenance_reports
  for insert
  with check (
    auth.uid() = owner_user_id
  );

create policy "maintenance_reports_update_own"
  on public.maintenance_reports
  for update
  using (
    auth.uid() = owner_user_id
  )
  with check (
    auth.uid() = owner_user_id
  );
