-- Sautero — Recipes navigation now mirrors Check List's section picker (Richard: "tak isto ako
-- v check liste"). Custom icon per recipe category, same pattern as station_icons
-- (38_station_icons.sql) — kitchen-wide, so a category created on one device shows the same
-- icon for everyone. Also lets a category exist as a browsable (empty) tile before any recipe
-- is actually tagged with it, same as a freshly-created Check List section.
create table if not exists recipe_category_icons (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  category text not null,
  icon text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (kitchen_id, category)
);
alter table recipe_category_icons enable row level security;

create policy "read kitchen recipe category icons" on recipe_category_icons
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen recipe category icons" on recipe_category_icons
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen recipe category icons" on recipe_category_icons
  for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen recipe category icons" on recipe_category_icons
  for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
