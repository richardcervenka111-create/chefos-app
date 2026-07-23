-- 186_clear_own_recipes_projects_checklists.sql
-- DESTRUCTIVE: empties Richard's own Recipes and Check Lists, on his explicit instruction
-- (24.7.2026): "chcem mať prázdne recepty a prázdne check listy vo všetkých týchto účtoch …
-- vymaž všetky do teraz vytvorene check listy a všetky do teraz vytvorené projekty v receptoch všade."
--
-- Runs only AFTER db/185, which promoted the recipes into the Sautero library — the content is
-- not lost, it became product content that every kitchen now carries (262 rows per kitchen).
--
-- SCOPE — checked before writing, and it turned out to be entirely Richard's own data:
--   recipe_lists   8 of 8 are his
--   projects       6 of 6 (the one in a foreign kitchen, "Burito" in "Mr. woof woof", was created
--                  by his own gmail account and holds 0 dishes)
--   prep_dishes    215 of 215 sit in his kitchens · prep_items 891
--   recipes        his 106 own rows (created_by = one of the five accounts)
-- No other user's work is touched. The Sautero shelf (created_by IS NULL) is NOT touched — that is
-- the product library and stays in every kitchen, which is exactly what "empty" means here: the
-- Moje and Firemné shelves go empty, the Sautero shelf keeps all 262.
--
-- DELETE ORDER follows the foreign keys, which are mostly NO ACTION rather than CASCADE:
--   prep_items -> prep_dishes is CASCADE (items go with their dish)
--   tasks -> projects, prep_dishes -> projects, recipes -> recipe_lists are all NO ACTION,
--   so children must go first or the delete errors out.
--
-- REVERSIBLE: every removed row is copied into the backup schema first (not exposed to PostgREST,
-- rights revoked from anon/authenticated, RLS on). Restore is a plain insert-select back.

create schema if not exists backup;
revoke all on schema backup from anon, authenticated;

do $$
declare
  acc uuid[];
begin
  select array_agg(id) into acc from public.profiles where lower(email) in
    ('richard.cervenka@icloud.com','richard.cervenka111@gmail.com','chefos@protonmail.com',
     'sautero_android@proton.me','sautero.guardian@atomicmail.io');

  -- 1. Snapshots.
  create table if not exists backup.own_recipes_20260724 as
    select * from public.recipes where created_by = any(acc);
  create table if not exists backup.recipe_lists_20260724 as
    select * from public.recipe_lists;
  create table if not exists backup.projects_20260724 as
    select * from public.projects;
  create table if not exists backup.prep_dishes_20260724 as
    select * from public.prep_dishes;
  create table if not exists backup.prep_items_20260724 as
    select * from public.prep_items;

  -- 2. DESTRUCTIVE, children first.
  delete from public.tasks where project_id is not null;
  delete from public.prep_dishes;              -- prep_items follow by CASCADE
  delete from public.projects;
  delete from public.recipes where created_by = any(acc);
  delete from public.recipe_lists;
end $$;

revoke all on all tables in schema backup from anon, authenticated;
alter table backup.own_recipes_20260724   enable row level security;
alter table backup.recipe_lists_20260724  enable row level security;
alter table backup.projects_20260724      enable row level security;
alter table backup.prep_dishes_20260724   enable row level security;
alter table backup.prep_items_20260724    enable row level security;

-- Restore (all of it):
--   insert into recipes      select * from backup.own_recipes_20260724;
--   insert into recipe_lists select * from backup.recipe_lists_20260724;
--   insert into projects     select * from backup.projects_20260724;
--   insert into prep_dishes  select * from backup.prep_dishes_20260724;
--   insert into prep_items   select * from backup.prep_items_20260724;
