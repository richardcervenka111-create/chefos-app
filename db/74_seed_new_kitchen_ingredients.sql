-- Sautero — new kitchens start with zero ingredients (2026-07-14).
--
-- Richard: "iné ako moje maily pravdepodobne nemajú ingrediencie... zisti a oprav to." Confirmed:
-- `ingredients` is scoped per kitchen_id (db/05), and the 2000-item database only ever got
-- seeded into Richard's own kitchen. handle_new_user() gives every brand-new signup
-- kitchen_id = null (db/34) -- if they create their OWN kitchen instead of joining an existing
-- one via invite, that new kitchen has a real row in `kitchens` but literally zero ingredient
-- rows. Same underlying gap likely applies to anything else that's kitchen-scoped and was only
-- ever seeded once (e.g. station_icons, recipe_category_icons) -- this migration only fixes
-- ingredients, the one Richard specifically flagged, since it's the single biggest piece of
-- "why does this app feel useful on day one" for a new kitchen.
--
-- Fix: whenever a new kitchen is created, copy every ingredient row from whichever existing
-- kitchen currently has the most of them (the de-facto reference dataset -- deliberately not
-- hardcoded to Richard's specific kitchen_id, so this keeps working correctly even if the
-- reference dataset moves or a bigger one is built later) into the new kitchen, with fresh ids.
-- Column list is read dynamically from information_schema rather than hand-copied, since this
-- table has picked up new columns in nearly every batch of work (nutrition, storage/season,
-- yield_pct, ...) -- a hand-written column list would silently go stale the next time one is
-- added and quietly drop that column from every new kitchen's copy.
--
-- Each new kitchen gets its OWN independent copy (not a live shared table) -- editing a price or
-- adding a note in one kitchen should never affect another's, same as ingredient pricing is
-- already understood to be genuinely kitchen/supplier-specific, not universal.
--
-- TEST ON chefos-staging FIRST.

create or replace function seed_new_kitchen_ingredients()
returns trigger as $$
declare
  reference_kitchen_id uuid;
  col_list text;
  select_list text;
begin
  -- Pick whichever kitchen currently has the most ingredient rows as the reference dataset.
  select kitchen_id into reference_kitchen_id
  from public.ingredients
  group by kitchen_id
  order by count(*) desc
  limit 1;

  if reference_kitchen_id is null or reference_kitchen_id = new.id then
    return new;
  end if;

  -- Every ingredients column except id/kitchen_id/created_at/updated_at, which all get fresh
  -- values below -- built dynamically so this never drifts out of sync with the real schema.
  select string_agg(quote_ident(column_name), ', ')
  into col_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'ingredients'
    and column_name not in ('id','kitchen_id','created_at','updated_at');

  select string_agg('src.' || quote_ident(column_name), ', ')
  into select_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'ingredients'
    and column_name not in ('id','kitchen_id','created_at','updated_at');

  execute format(
    'insert into public.ingredients (id, kitchen_id, %s, created_at, updated_at)
     select gen_random_uuid(), %L, %s, now(), now()
     from public.ingredients src where src.kitchen_id = %L',
    col_list, new.id, select_list, reference_kitchen_id
  );

  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_kitchen_created_seed_ingredients on kitchens;
create trigger on_kitchen_created_seed_ingredients
  after insert on kitchens
  for each row execute function seed_new_kitchen_ingredients();

-- ---------- Backfill: fix kitchens that were already created empty ----------
-- Any existing kitchen that currently has zero ingredients gets seeded right now too, the same
-- way, so this fixes kitchens that already exist (e.g. Richard's own gmail test above), not just
-- ones created from this point forward.
do $$
declare
  reference_kitchen_id uuid;
  empty_kitchen record;
  col_list text;
  select_list text;
begin
  select kitchen_id into reference_kitchen_id
  from public.ingredients
  group by kitchen_id
  order by count(*) desc
  limit 1;

  if reference_kitchen_id is null then
    return;
  end if;

  select string_agg(quote_ident(column_name), ', ')
  into col_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'ingredients'
    and column_name not in ('id','kitchen_id','created_at','updated_at');

  select string_agg('src.' || quote_ident(column_name), ', ')
  into select_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'ingredients'
    and column_name not in ('id','kitchen_id','created_at','updated_at');

  for empty_kitchen in
    select k.id from kitchens k
    where k.id <> reference_kitchen_id
      and not exists (select 1 from public.ingredients i where i.kitchen_id = k.id)
  loop
    execute format(
      'insert into public.ingredients (id, kitchen_id, %s, created_at, updated_at)
       select gen_random_uuid(), %L, %s, now(), now()
       from public.ingredients src where src.kitchen_id = %L',
      col_list, empty_kitchen.id, select_list, reference_kitchen_id
    );
  end loop;
end $$;
