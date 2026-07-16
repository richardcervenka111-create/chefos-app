-- ChefOS — shared ingredients stay admin-only to add (Richard, 16.7., follow-up to db/97's
-- "My Ingredients"). The kitchen-wide "ChefOS" shelf keeps the same admin-only convention the
-- original Custom Ingredients feature used; the new personal "My Ingredients" shelf (is_personal)
-- stays open to everyone, since that's the whole point of it.
--
-- "Admin" here means ANY kind of admin — Head Admin (is_admin) or a Kitchen Admin with any
-- admin_perms flag set — not just Richard personally, since Create Team (db/97) means real
-- restaurants now have their own admins managing their own kitchen's catalog.

create or replace function _has_any_admin_role()
returns boolean
language sql
security definer
set search_path = public
as $$
  select coalesce(
    (select is_admin or exists(
      select 1 from jsonb_each(coalesce(admin_perms, '{}'::jsonb)) e where e.value = 'true'::jsonb
    ) from profiles where id = auth.uid()),
    false
  );
$$;

drop policy if exists "write kitchen ingredients" on ingredients;
create policy "write kitchen ingredients" on ingredients
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    and (
      (is_personal and created_by = auth.uid())
      or (not is_personal and _has_any_admin_role())
    )
  );

-- Editing/deleting an existing shared item also stays admin-only; personal items stay
-- owner-only, same split as insert above.
drop policy if exists "update kitchen ingredients" on ingredients;
create policy "update kitchen ingredients" on ingredients
  for update using (
    (is_personal and created_by = auth.uid())
    or (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and _has_any_admin_role())
  );

drop policy if exists "delete kitchen ingredients" on ingredients;
create policy "delete kitchen ingredients" on ingredients
  for delete using (
    (is_personal and created_by = auth.uid())
    or (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and _has_any_admin_role())
  );
