-- 156: Order List — personal vs company context split (Richard, 18.7., said TWICE and the
-- second time in anger after the first miss: "ak v personal profile si nahádžem do
-- objednávkového listu čo chcem kúpiť domov tak nechcem aby to videl nejaký môj kolega!!!!").
--
-- The trap: a team member's profiles.kitchen_id points at the COMPANY kitchen even while their
-- account_type is 'personal' — personal/company is a display mode, not a different kitchen. So
-- order_list_items, scoped only by kitchen_id (db/12/76), mixed personal-mode home-shopping
-- rows into the company's shared order list. Privacy violation, live.
--
-- Fix, three parts in one file:
--   1) is_personal column — set by the app from account_type at write time. Default false =
--      every EXISTING row keeps today's company/shared behaviour, no backfill needed.
--   2) Unique constraint gains is_personal — without this, the app's upsert
--      (onConflict kitchen,station,ingredient,creator) would MATCH a company row while saving
--      in personal mode and silently flip its is_personal: corrupting the exact privacy field.
--   3) RLS: personal rows are readable/updatable/deletable ONLY by their creator — enforced at
--      the database, not just hidden by the UI. Company rows keep exactly today's kitchen-wide
--      policies (db/76's "nobody's save deletes someone else's row" stays app-side scoping).
--
-- STAGING FIRST class — changes a unique constraint AND RLS policies on a live table
-- (db/README rules 3 + 7). Run on chefos-staging, verify, then production.

alter table order_list_items add column if not exists is_personal boolean not null default false;

do $$
declare
  old_constraint_name text;
begin
  select con.conname into old_constraint_name
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  where rel.relname = 'order_list_items'
    and con.contype = 'u'
    and (
      select array_agg(attname::text order by attnum)
      from pg_attribute
      where attrelid = con.conrelid and attnum = any(con.conkey)
    ) = array['kitchen_id','station','ingredient_id','created_by'];

  if old_constraint_name is not null then
    execute format('alter table order_list_items drop constraint %I', old_constraint_name);
  end if;
end $$;

alter table order_list_items
  add constraint order_list_items_kitchen_station_ingredient_creator_mode_key
  unique (kitchen_id, station, ingredient_id, created_by, is_personal);

drop policy if exists "read kitchen order list" on order_list_items;
create policy "read kitchen order list" on order_list_items
  for select using (
    (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
    or (is_personal and created_by = auth.uid())
  );

drop policy if exists "update kitchen order list" on order_list_items;
create policy "update kitchen order list" on order_list_items
  for update using (
    (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
    or (is_personal and created_by = auth.uid())
  );

drop policy if exists "delete kitchen order list" on order_list_items;
create policy "delete kitchen order list" on order_list_items
  for delete using (
    (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
    or (is_personal and created_by = auth.uid())
  );

-- INSERT: personal rows must be your own; company rows unchanged (kitchen-wide).
drop policy if exists "write kitchen order list" on order_list_items;
create policy "write kitchen order list" on order_list_items
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    and (not is_personal or created_by = auth.uid())
  );
