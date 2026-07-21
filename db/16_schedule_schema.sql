-- Sautero — Schedule: a simple daily staff roster, organized by station.
-- Sketch-level v1 (plain staff names as text, not full user accounts) — refine once there's
-- a real reference (e.g. the roster format Richard already uses at work) to match against.
create table if not exists schedule_entries (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  work_date date not null,
  station text,
  staff_name text not null,
  shift text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

alter table schedule_entries enable row level security;

create policy "read kitchen schedule" on schedule_entries
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "write kitchen schedule" on schedule_entries
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "update kitchen schedule" on schedule_entries
  for update using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "delete kitchen schedule" on schedule_entries
  for delete using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
