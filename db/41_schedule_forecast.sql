-- Sautero — Working Time: "Upload schedule" lets a person scan their real roster (Dienstplan
-- PDF/photo, same format as the Schedule feature) and pull out just their own row, so Working
-- Time can show a bar chart of past AND future scheduled work days — not just what's already
-- been checked in. Reuses the existing shift_codes dictionary (18_schedule_v2_schema.sql) to
-- turn a code like "PJM" into actual hours, instead of re-parsing the PDF's legend — same
-- source of truth the Schedule grid already uses.
create table if not exists schedule_forecast (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  user_id uuid not null references auth.users(id),
  work_date date not null,
  shift_code text,
  hours numeric,
  is_absence boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, work_date)
);
alter table schedule_forecast enable row level security;

create policy "read own schedule forecast" on schedule_forecast
  for select using (user_id = auth.uid());
create policy "insert own schedule forecast" on schedule_forecast
  for insert with check (user_id = auth.uid() and kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update own schedule forecast" on schedule_forecast
  for update using (user_id = auth.uid());
create policy "delete own schedule forecast" on schedule_forecast
  for delete using (user_id = auth.uid());
