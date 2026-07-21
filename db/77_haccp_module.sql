-- Sautero — HACCP module, wave 1 (15.7.). Richard: full HACCP hub page (goods receiving, core
-- cooking temp, cooling log, cleaning + personal hygiene checklists now; fryer oil quality,
-- pest control, label expiry, staff training, admin report in later waves), same size/style
-- tiles as the main Home grid, plus Fridge Temp moves in here too.
--
-- Two reusable engines instead of one table per checkpoint, since several of these share the
-- same real shape:
--   - haccp_checklist_items/_log: a recurring task that someone ticks off (cleaning, personal
--     hygiene now; pest control in wave 2 — same shape, just a different category).
--   - haccp_measurement_log: a single reading + pass/fail judgement (goods receiving, core
--     cooking temperature, cooling log now; fryer oil in wave 2 — same shape, different type).
-- Both check constraints already list the wave-2 values so this migration doesn't need to be
-- touched again when pest control / fryer oil get built.

create table if not exists haccp_checklist_items (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  category text not null check (category in ('cleaning','hygiene','pest_control')),
  station text,
  task text not null,
  frequency text not null default 'daily' check (frequency in ('daily','weekly','monthly')),
  active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists haccp_checklist_log (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  item_id uuid not null references haccp_checklist_items(id) on delete cascade,
  status text not null check (status in ('ok','issue')),
  note text,
  completed_by uuid references auth.users(id),
  completed_at timestamptz not null default now()
);

create table if not exists haccp_measurement_log (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  type text not null check (type in ('goods_receiving','core_cooking','cooling','fryer_oil')),
  label text not null,
  value_numeric numeric,
  value_unit text,
  status text not null default 'ok' check (status in ('ok','issue')),
  note text,
  logged_by uuid references auth.users(id),
  logged_at timestamptz not null default now()
);

alter table haccp_checklist_items enable row level security;
alter table haccp_checklist_log enable row level security;
alter table haccp_measurement_log enable row level security;

create policy "read kitchen haccp checklist items" on haccp_checklist_items
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen haccp checklist items" on haccp_checklist_items
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen haccp checklist items" on haccp_checklist_items
  for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen haccp checklist items" on haccp_checklist_items
  for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));

create policy "read kitchen haccp checklist log" on haccp_checklist_log
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen haccp checklist log" on haccp_checklist_log
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen haccp checklist log" on haccp_checklist_log
  for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));

create policy "read kitchen haccp measurement log" on haccp_measurement_log
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen haccp measurement log" on haccp_measurement_log
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen haccp measurement log" on haccp_measurement_log
  for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
