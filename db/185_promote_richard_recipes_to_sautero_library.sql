-- 185_promote_richard_recipes_to_sautero_library.sql
-- Richard, 24.7.2026: "zober tie recepty a pridaj ich do sautero receptov ... v sautero receptoch
-- chcem mať o tento zoznam rozšírenú databázu pre každeho nového uživatela."
--
-- HOW THE SAUTERO SHELF ACTUALLY WORKS (db/87): a recipe belongs to the built-in Sautero library
-- when created_by IS NULL. A new kitchen is seeded by the seed_new_kitchen_recipes() trigger,
-- which copies every created_by IS NULL row out of the REFERENCE KITCHEN — whichever kitchen
-- currently holds the most library rows. Today that is the kitchen named "new name" (183 rows),
-- NOT one of Richard's. So the library grows by inserting into that kitchen with created_by NULL;
-- every kitchen created from then on inherits the bigger library automatically.
--
-- WHAT GOES IN: Richard's 106 own recipes carry only 91 distinct titles (the rest are the same
-- dish saved in a second kitchen/mode/project), and 12 of those titles already exist in the
-- library. So 79 genuinely new recipes are promoted. Where a title exists more than once, the
-- richest copy wins (longest `sections`, then newest) — not an arbitrary one.
--
-- ADDITIVE ONLY: nothing is deleted or overwritten here. Richard's own rows stay exactly where
-- they are; this migration only writes new library rows. Reverse it with the delete at the bottom.
--
-- The copies are stripped of everything personal before they become product content:
--   created_by NULL (that IS the Sautero shelf) · list_id NULL (projects are per-user)
--   is_personal false · is_public/published_at cleared (library rows are not "published" by a user)
--   shared_with_friends / shared_with_chefos false · chefos_master_id NULL · is_custom false
-- and the stored `Salads &amp; Starters` category glitch on two recipes is corrected to a real "&"
-- so the product library does not inherit a broken category name.

do $$
declare
  ref_kitchen uuid;
  col_list text;
  select_list text;
begin
  select kitchen_id into ref_kitchen
  from public.recipes where created_by is null
  group by kitchen_id order by count(*) desc limit 1;

  if ref_kitchen is null then
    raise exception 'no reference kitchen found — aborting';
  end if;

  -- Titles the library already has, captured BEFORE the insert so the clean-up step below can
  -- identify exactly the rows this migration created.
  create temp table _lib_before on commit drop as
    select distinct lower(trim(title)) t
    from public.recipes where created_by is null and kitchen_id = ref_kitchen;

  -- One row per title — the most complete copy.
  create temp table _pick on commit drop as
    select distinct on (lower(trim(r.title))) r.*
    from public.recipes r
    join public.profiles p on p.id = r.created_by
    where lower(p.email) in ('richard.cervenka@icloud.com','richard.cervenka111@gmail.com',
      'chefos@protonmail.com','sautero_android@proton.me','sautero.guardian@atomicmail.io')
      and lower(trim(r.title)) not in (select t from _lib_before)
    order by lower(trim(r.title)), length(coalesce(r.sections::text,'')) desc, r.created_at desc;

  -- Dynamic column list for the same reason db/87 uses one: recipes gains columns over time and
  -- a hand-written list would silently go stale.
  select string_agg(quote_ident(column_name), ', '), string_agg('src.' || quote_ident(column_name), ', ')
  into col_list, select_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'recipes'
    and column_name not in ('id','kitchen_id','created_by','created_at','updated_at');

  execute format(
    'insert into public.recipes (id, kitchen_id, %s, created_by, created_at, updated_at)
     select gen_random_uuid(), %L, %s, null, now(), now() from _pick src',
    col_list, ref_kitchen, select_list);

  update public.recipes set
      list_id = null,
      is_personal = false,
      is_public = false,
      published_at = null,
      shared_with_friends = false,
      shared_with_chefos = false,
      chefos_master_id = null,
      is_custom = false,
      category = replace(coalesce(category,''), '&amp;', '&')
  where created_by is null
    and kitchen_id = ref_kitchen
    and lower(trim(title)) not in (select t from _lib_before);

  -- Every library recipe carries a chefos_master_id: a stable uuid shared by that recipe's copy
  -- in all 44 kitchens, which is what lets comments (db/119, db/129) follow one recipe across
  -- kitchens. The copies above started with a NULL there, which would have quietly excluded them
  -- from that mechanism forever. Each new library row gets its own fresh master id; the seeding
  -- trigger copies the column, so every future kitchen's copy inherits the same one.
  update public.recipes set chefos_master_id = gen_random_uuid()
  where created_by is null and chefos_master_id is null and kitchen_id = ref_kitchen;
end $$;

-- Reverse (only valid immediately after this migration, before the library is edited again):
--   delete from recipes r using kitchens k
--    where r.kitchen_id = k.id and k.name = 'new name' and r.created_by is null
--      and r.created_at::date = date '2026-07-24';
