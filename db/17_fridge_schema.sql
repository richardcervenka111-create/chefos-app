-- Sautero — Fridge Temperature: manual logging v1 (name the units, log a reading, see
-- whether it's in range). Wireless-sensor auto-logging is future work — this is the
-- practical starting point: usable today, without needing any hardware.
create table if not exists fridges (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  name text not null,
  target_min numeric,
  target_max numeric,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists fridge_logs (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  fridge_id uuid not null references fridges(id) on delete cascade,
  temperature_c numeric not null,
  checked_by uuid references auth.users(id),
  checked_at timestamptz not null default now(),
  notes text
);

alter table fridges enable row level security;
alter table fridge_logs enable row level security;

create policy "read kitchen fridges" on fridges
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen fridges" on fridges
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen fridges" on fridges
  for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen fridges" on fridges
  for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));

create policy "read kitchen fridge logs" on fridge_logs
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen fridge logs" on fridge_logs
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen fridge logs" on fridge_logs
  for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
