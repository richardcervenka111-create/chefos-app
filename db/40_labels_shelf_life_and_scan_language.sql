-- Sautero — two small additions:
--
-- 1) Print Labels: per-product shelf life (days), used to auto-compute the "use by" date
--    printed on a label from the actual print date. Kitchen-wide (everyone printing "Ravioli"
--    labels should see the same rule) but locked down after the first person sets it: anyone
--    can create it once, only an admin ("hlavné zariadenie") can change it afterward — shelf
--    life is food-safety-critical and shouldn't be casually edited by anyone at any time.
create table if not exists print_label_settings (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  name text not null,
  shelf_life_days int,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  unique (kitchen_id, name)
);
alter table print_label_settings enable row level security;

create policy "read kitchen label settings" on print_label_settings
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "insert kitchen label settings" on print_label_settings
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "admin update kitchen label settings" on print_label_settings
  for update using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    and exists (select 1 from profiles where id = auth.uid() and is_admin)
  );

-- 2) Scan auto-translate: per-user preference for the language photo-scanned recipes/prep
--    sheets get translated into. NULL = default (English, per Richard's request that this is
--    on by default); 'off' = keep the original language; any other value is a language name
--    Claude is asked to translate into.
alter table user_settings add column if not exists scan_language text;
