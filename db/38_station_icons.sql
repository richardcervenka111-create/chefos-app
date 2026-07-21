-- Sautero — custom icon per section, chosen when creating it (instead of always falling back
-- to the generic 📍 pin for anything not in the hardcoded STATION_ICONS map). Kitchen-wide
-- (not device-local like hidden-station-tiles/print-queue) since an icon is part of a
-- section's shared identity — everyone on the team should see the same one.
create table if not exists station_icons (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  station text not null,
  icon text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (kitchen_id, station)
);
alter table station_icons enable row level security;

create policy "read kitchen station icons" on station_icons
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen station icons" on station_icons
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen station icons" on station_icons
  for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
