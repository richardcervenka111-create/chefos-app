-- ChefOS — Order List: don't let one person's save wipe out someone else's (bod 4, 2026-07-15).
--
-- Richard: order list should stay shared with the whole team, sum quantities when the same
-- ingredient is ordered more than once, and let the kitchen admin see who ordered what before
-- approving it to go to the supplier.
--
-- Found two real bugs on the way to that:
-- 1) order_list_items had one row per (kitchen, station, ingredient) for the WHOLE KITCHEN.
--    Adding the same ingredient a second time (even by a different person) silently overwrote
--    the first person's quantity instead of summing.
-- 2) Far worse: the station-picker's Save button (saveOrderList() in app/index.html) deleted
--    EVERY row for that station across the whole kitchen, then re-inserted only what the current
--    person had checked -- so if person B opened the Grill picker, unchecked one of person A's
--    items by mistake, and saved, person A's OTHER items silently vanished too. Not just a
--    summing bug -- real, silent data loss between teammates.
--
-- Fix: one row per (kitchen, station, ingredient, created_by) instead of per (kitchen, station,
-- ingredient) -- each person's own contribution is its own row, nobody's save can delete
-- someone else's row. The app-side summary view (updated separately in app/index.html) now sums
-- quantities across everyone's rows for the "how much to order" total, with a per-person
-- breakdown visible to the kitchen admin only.
--
-- TEST ON chefos-staging FIRST -- this changes a unique constraint on a live table.

do $$
declare
  old_constraint_name text;
begin
  -- Find the existing 3-column unique constraint by its actual columns, not by a guessed name
  -- (it was declared inline in CREATE TABLE, so Postgres auto-named it).
  select con.conname into old_constraint_name
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  where rel.relname = 'order_list_items'
    and con.contype = 'u'
    and (
      select array_agg(attname order by attnum)
      from pg_attribute
      where attrelid = con.conrelid and attnum = any(con.conkey)
    ) = array['kitchen_id','station','ingredient_id'];

  if old_constraint_name is not null then
    execute format('alter table order_list_items drop constraint %I', old_constraint_name);
  end if;
end $$;

alter table order_list_items
  add constraint order_list_items_kitchen_station_ingredient_creator_key
  unique (kitchen_id, station, ingredient_id, created_by);
