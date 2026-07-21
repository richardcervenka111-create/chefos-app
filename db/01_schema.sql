-- Sautero — Phase 1a database schema
-- Run this ONCE in the Supabase SQL Editor (Dashboard → SQL Editor → New query → paste → Run).
-- Plain-language guide: this creates the "shelves" in your shared digital storeroom —
-- one shelf (table) for kitchens, one for people, one for recipes.

-- 1) KITCHENS — one row per restaurant/kitchen using Sautero. Just one row for now (yours).
create table if not exists kitchens (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

-- 2) PROFILES — one row per person, linked to Supabase's built-in login system (auth.users)
-- and to a kitchen + role. Roles aren't enforced yet (that's Phase 2) — the column just
-- exists now so we don't have to change the shape of the table later.
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  kitchen_id uuid references kitchens(id),
  full_name text,
  role text check (role in ('chef','sous_chef','chef_de_partie','commis','manager')),
  created_at timestamptz not null default now()
);

-- 3) RECIPES — the main table. Columns map directly to the standardized recipe format.
-- Fields that don't exist in the old recipe book yet (chef_notes, storage, shelf_life,
-- variations, scaling_notes, equipment, plating_suggestions, allergens, tags, cuisine,
-- station, image_url, cross_references) are simply empty until filled in through the app —
-- nothing is lost, there was just nowhere to put this information before.
create table if not exists recipes (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),

  title text not null,
  subtitle text,              -- short line shown under the title (what "meta" used to be)
  description text,           -- longer editorial description (new field, empty at first)

  category text,
  station text,                -- e.g. Grill, Cold Kitchen, Pastry (new field)
  cuisine text,                 -- new field
  difficulty text check (difficulty in ('Easy','Medium','Hard')),

  yield_text text,             -- e.g. "Serves 4", "2 loaves"
  prep_time_active text,       -- hands-on time, e.g. "35 min"
  prep_time_passive text,      -- resting/baking/proofing time, e.g. "1.9 hr"

  equipment text,              -- new field
  chef_notes text,             -- new field
  storage text,                -- new field
  shelf_life text,             -- new field
  variations text,             -- new field
  scaling_notes text,          -- new field
  plating_suggestions text,    -- new field
  cross_references text,       -- new field (chef-curated; separate from auto "Used In")

  cost_total numeric,
  cost_per_kg numeric,
  allergens text[] not null default '{}',
  tags text[] not null default '{}',
  image_url text,

  -- The ingredient tables / method steps / free-text notes that make up the body of the
  -- recipe. Kept as one flexible block (like the layout of a recipe card), same shape the
  -- app already uses today, so all existing editing logic carries over unchanged.
  sections jsonb not null default '[]',

  is_custom boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4) FAVORITES — which recipes a person has starred
create table if not exists favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  recipe_id uuid not null references recipes(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, recipe_id)
);

-- 5) RECIPE_NOTES — a person's private notes on a recipe ("My Notes" in the app)
create table if not exists recipe_notes (
  user_id uuid not null references auth.users(id) on delete cascade,
  recipe_id uuid not null references recipes(id) on delete cascade,
  note text not null default '',
  updated_at timestamptz not null default now(),
  primary key (user_id, recipe_id)
);

-- ---------- Security: lock every table down, then open it only to logged-in kitchen staff ----------
-- Plain-language: by default nobody (not even someone with the public app key) can read or
-- write anything. We then add specific, narrow rules — like a kitchen door that's locked
-- unless you're on staff.

alter table kitchens enable row level security;
alter table profiles enable row level security;
alter table recipes enable row level security;
alter table favorites enable row level security;
alter table recipe_notes enable row level security;

-- A logged-in person can see their own profile and their kitchen's profiles/recipes.
create policy "read own profile" on profiles
  for select using (auth.uid() = id);

create policy "read kitchen recipes" on recipes
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "write kitchen recipes" on recipes
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "update kitchen recipes" on recipes
  for update using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "delete own custom recipes" on recipes
  for delete using (
    is_custom and kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );

create policy "read own favorites" on favorites
  for select using (auth.uid() = user_id);
create policy "manage own favorites" on favorites
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "read own notes" on recipe_notes
  for select using (auth.uid() = user_id);
create policy "manage own notes" on recipe_notes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- When someone signs up (via Supabase Auth), automatically create their profile row
-- and attach them to the one kitchen that exists so far. (Phase 2 will make this smarter —
-- e.g. invite links to a specific kitchen — this is a simple placeholder for now.)
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, kitchen_id)
  values (new.id, (select id from kitchens order by created_at asc limit 1));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();
