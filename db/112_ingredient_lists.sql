-- ChefOS — custom ingredient lists (Richard, 16.7. večer): people can create ADDITIONAL
-- ingredient lists alongside the two fixed shelves (ChefOS and My Ingredients, which are
-- hard-wired and can never be renamed/deleted). Long-press on a list tile in the Ingredients
-- menu offers Rename / Hide / Delete — for custom lists only.
--
-- Model: a custom list is a named container owned by its creator, private to them (same
-- privacy rule as My Ingredients). Its items live in the normal `ingredients` table with
-- is_personal = true (so all existing privacy RLS from db/97 applies untouched) plus a
-- list_id pointing here. My Ingredients = is_personal items with list_id NULL. The ChefOS
-- shelf (is_personal = false) never mixes with any of this.

create table if not exists ingredient_lists (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  created_by uuid not null references profiles(id),
  name text not null,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);

alter table ingredient_lists enable row level security;

-- Private to their creator, exactly like the personal ingredients they contain.
create policy "own ingredient lists" on ingredient_lists
  for all using (created_by = auth.uid()) with check (created_by = auth.uid());

alter table ingredients add column if not exists list_id uuid references ingredient_lists(id);
grant select (list_id) on ingredients to authenticated;

-- The per-owner uniqueness from db/97 said "one 'Basil' per person across ALL their personal
-- items" — with multiple lists, the same name must be allowed once PER LIST instead.
drop index if exists ingredients_personal_name_uidx;
create unique index if not exists ingredients_personal_name_uidx
  on ingredients (kitchen_id, lower(name), created_by, coalesce(list_id, '00000000-0000-0000-0000-000000000000'::uuid))
  where is_personal;
