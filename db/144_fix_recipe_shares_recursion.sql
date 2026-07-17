-- 144: fix "infinite recursion detected in policy for relation recipe_shares" (Richard,
-- 17.7.2026 večer — hit on the very first live share attempt).
--
-- Root cause: db/143 created a cycle between the two tables' policies —
--   recipes.recipes_select_shared_to_me  → subquery on recipe_shares
--   recipe_shares.rs_owner_manage (WITH CHECK) → subquery on recipes
-- Postgres refuses to plan the insert because each table's RLS pulls in the other's.
--
-- Fix: break the cycle with two SECURITY DEFINER helper functions. Each runs as the table
-- owner (bypassing RLS inside the function body), so evaluating one table's policy no longer
-- triggers the other table's policies. Both functions pin search_path (the db/73 lesson) and
-- keep their checks EXACTLY as strict as the inline versions they replace.

create or replace function recipe_is_shared_with_me(rid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from recipe_shares rs
    where rs.recipe_id = rid and rs.friend_id = auth.uid()
  );
$$;

create or replace function i_own_personal_recipe(rid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from recipes r
    where r.id = rid and r.created_by = auth.uid() and r.is_personal
  );
$$;

drop policy if exists recipes_select_shared_to_me on recipes;
create policy recipes_select_shared_to_me on recipes
  for select using ( recipe_is_shared_with_me(id) );

drop policy if exists rs_owner_manage on recipe_shares;
create policy rs_owner_manage on recipe_shares
  for all using (owner_id = auth.uid())
  with check (
    owner_id = auth.uid()
    and i_own_personal_recipe(recipe_id)
    and exists (select 1 from profiles p where p.id = auth.uid() and p.account_type = 'personal')
    and exists (select 1 from chef_connections c
                where (c.user_a = auth.uid() and c.user_b = friend_id)
                   or (c.user_b = auth.uid() and c.user_a = friend_id))
  );
