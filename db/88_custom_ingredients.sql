-- ChefOS -- admin-only custom ingredients, as a separate list from the main ingredients
-- catalog (Richard, 16.7., bod 2): "ingrediencie v admin účtoch musia mať možnosť pridať
-- vlastné ingrediencie s funkciou vloženia súboru rôznych formátov, tieto budú v novej funkcii
-- vo vrchnej lište ako separátny zoznam" -- admin accounts get a way to add custom ingredients
-- via file upload (any format), landing in a new top-bar feature as their own separate list.
--
-- Deliberately its own table, not a flag bolted onto `ingredients` (db/05): the main catalog
-- is a heavily-curated 2000-item reference price book with season/storage/allergen/substitute
-- fields; a quickly-uploaded supplier sheet or handwritten list doesn't need any of that, and
-- mixing "curated reference data" with "whatever an admin just scanned in" would make both
-- harder to trust. Kept genuinely simple on purpose.
--
-- Read: any team member (useful context for anyone in the kitchen). Write: admin only
-- (is_admin, matching the existing admin-only topbar-icon convention already used for
-- Currency) -- not extended to Kitchen Admin (admin_perms, db/85) since Richard's wording was
-- specifically "admin účtoch" without naming which tier, and this is easy to widen later with
-- one more admin_perms key if he wants kitchen admins to have it too.
--
-- Safe straight to production: brand-new table, nothing existing changes.

create table if not exists custom_ingredients (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),

  name text not null,
  unit text,
  price numeric,
  category text,
  note text,
  source_file_name text,

  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

alter table custom_ingredients enable row level security;

create policy "read kitchen custom ingredients" on custom_ingredients
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "admin writes custom ingredients" on custom_ingredients
  for insert with check (
    exists (
      select 1 from profiles
      where id = auth.uid() and kitchen_id = custom_ingredients.kitchen_id and is_admin
    )
  );
create policy "admin deletes custom ingredients" on custom_ingredients
  for delete using (
    exists (
      select 1 from profiles
      where id = auth.uid() and kitchen_id = custom_ingredients.kitchen_id and is_admin
    )
  );
