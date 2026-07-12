-- ChefOS — ingredients master list (pricing database)
-- Run this in the Supabase SQL Editor, AFTER 01-04. Creates the "price book" table —
-- one row per distinct ingredient, with a current reference price you can edit any time.

create table if not exists ingredients (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),

  name text not null,
  aliases text[] not null default '{}',   -- alternate spellings, so recipe text can still match
  cuisine text check (cuisine in ('European','Asian','Universal')),
  category text,                           -- e.g. Produce, Dairy, Meat, Spices & Seasonings...

  unit text not null check (unit in ('kg','l','pc')),  -- the unit the price is quoted in
  price numeric,
  price_currency text not null default 'EUR',
  price_updated_at timestamptz,

  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists ingredients_kitchen_name_uidx
  on ingredients (kitchen_id, lower(name));

alter table ingredients enable row level security;

create policy "read kitchen ingredients" on ingredients
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "write kitchen ingredients" on ingredients
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "update kitchen ingredients" on ingredients
  for update using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "delete kitchen ingredients" on ingredients
  for delete using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
