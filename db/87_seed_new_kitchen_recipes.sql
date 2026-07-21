-- Sautero -- new kitchens start with zero recipes, same bug class as db/74's ingredients gap
-- (Richard, 16.7., bod 1): "nový uživatelia musia mať recipes ale všetky budú v priečinku
-- sautero" -- new users must have recipes, but all of them go into the Sautero shelf.
--
-- recipes is kitchen_id-scoped (db/01) and the 173 migrated library recipes only ever got
-- seeded into one kitchen. The three-way shelf filter (app/index.html, setRecipeSourceFilter)
-- reads the shelf straight off created_by: NULL = Sautero (the built-in library), = me = Moje,
-- = someone else = Firemné. Copying "all recipes" the way db/74 copies ingredients would be
-- wrong here -- it would drag a reference kitchen's personally-authored (Moje) recipes into
-- every new kitchen too, landing them in the new kitchen's Firemné shelf (since created_by
-- would no longer be the new kitchen's own user). This migration only ever copies rows where
-- created_by IS NULL, and keeps created_by NULL on the copy -- exactly "all in the Sautero
-- folder", nothing else leaks across kitchens.
--
-- Same dynamic-column-list approach as db/74, for the same reason: recipes has picked up new
-- columns before and will again, a hand-written list would silently go stale.
--
-- TEST ON chefos-staging FIRST -- writes real data to every kitchen, same class as db/74.

create or replace function seed_new_kitchen_recipes()
returns trigger as $$
declare
  reference_kitchen_id uuid;
  col_list text;
  select_list text;
begin
  -- Whichever kitchen currently holds the most Sautero-shelf (created_by IS NULL) recipes is
  -- the reference library -- not just "most recipes overall", which could be skewed by one
  -- kitchen's personal (Moje) collection.
  select kitchen_id into reference_kitchen_id
  from public.recipes
  where created_by is null
  group by kitchen_id
  order by count(*) desc
  limit 1;

  if reference_kitchen_id is null or reference_kitchen_id = new.id then
    return new;
  end if;

  select string_agg(quote_ident(column_name), ', ')
  into col_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'recipes'
    and column_name not in ('id','kitchen_id','created_by','created_at','updated_at');

  select string_agg('src.' || quote_ident(column_name), ', ')
  into select_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'recipes'
    and column_name not in ('id','kitchen_id','created_by','created_at','updated_at');

  execute format(
    'insert into public.recipes (id, kitchen_id, %s, created_by, created_at, updated_at)
     select gen_random_uuid(), %L, %s, null, now(), now()
     from public.recipes src where src.kitchen_id = %L and src.created_by is null',
    col_list, new.id, select_list, reference_kitchen_id
  );

  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_kitchen_created_seed_recipes on kitchens;
create trigger on_kitchen_created_seed_recipes
  after insert on kitchens
  for each row execute function seed_new_kitchen_recipes();

-- ---------- Backfill: fix kitchens that were already created with zero Sautero-shelf recipes ----------
do $$
declare
  reference_kitchen_id uuid;
  empty_kitchen record;
  col_list text;
  select_list text;
begin
  select kitchen_id into reference_kitchen_id
  from public.recipes
  where created_by is null
  group by kitchen_id
  order by count(*) desc
  limit 1;

  if reference_kitchen_id is null then
    return;
  end if;

  select string_agg(quote_ident(column_name), ', ')
  into col_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'recipes'
    and column_name not in ('id','kitchen_id','created_by','created_at','updated_at');

  select string_agg('src.' || quote_ident(column_name), ', ')
  into select_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'recipes'
    and column_name not in ('id','kitchen_id','created_by','created_at','updated_at');

  for empty_kitchen in
    select k.id from kitchens k
    where k.id <> reference_kitchen_id
      and not exists (
        select 1 from public.recipes r where r.kitchen_id = k.id and r.created_by is null
      )
  loop
    execute format(
      'insert into public.recipes (id, kitchen_id, %s, created_by, created_at, updated_at)
       select gen_random_uuid(), %L, %s, null, now(), now()
       from public.recipes src where src.kitchen_id = %L and src.created_by is null',
      col_list, empty_kitchen.id, select_list, reference_kitchen_id
    );
  end loop;
end $$;
