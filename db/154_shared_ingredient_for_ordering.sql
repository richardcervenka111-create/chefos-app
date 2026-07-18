-- 154: fixes a real bug Richard hit live (18.7.): ordering something not yet in the price book
-- created it as a PERSONAL ingredient (is_personal:true, created_by:me) — that satisfied RLS
-- for the insert (db/105 only lets admins create SHARED ingredients directly), but personal
-- ingredients are only visible to their own creator (db/97's read policy: "created_by =
-- auth.uid()" for is_personal rows). Result: the order_list_items row existed kitchen-wide, but
-- the admin (or any other team member) opening Order List saw "(ingredient removed)" instead of
-- the name — exactly the "personal mode item doesn't show in the company order list" report,
-- and the opposite of what Order List is for (admin sees what everyone needs and orders it
-- manually, per Richard: no contracted suppliers yet).
--
-- Fix: a narrow SECURITY DEFINER RPC lets ANY kitchen member create a bare-bones SHARED
-- ingredient (is_personal:false) — visible to the whole team — without needing an admin role.
-- This is the one legitimate case where db/105's admin-only shared-write gate needs a controlled
-- exception: ordering something new must never be blocked, and it must never be invisible to
-- the person acting on the order.
--
-- Safe straight to production — new function only, no schema/data changes, no RLS policy
-- changes (the RLS gate stays exactly as strict for every other insert path).

create or replace function create_shared_ingredient(p_name text, p_unit text default 'kg', p_category text default null, p_aliases text[] default '{}')
returns ingredients
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kitchen_id uuid;
  v_row ingredients;
begin
  select kitchen_id into v_kitchen_id from profiles where id = auth.uid();
  if v_kitchen_id is null then
    raise exception 'Not in a kitchen';
  end if;
  insert into ingredients (kitchen_id, name, unit, category, aliases, is_personal, created_by)
    values (v_kitchen_id, p_name, coalesce(nullif(p_unit, ''), 'kg'), p_category, coalesce(p_aliases, '{}'), false, auth.uid())
    returning * into v_row;
  return v_row;
end;
$$;
grant execute on function create_shared_ingredient(text, text, text, text[]) to authenticated;
