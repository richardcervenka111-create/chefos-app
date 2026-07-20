-- db/164: super-admin can UPDATE any profile (Admin Directory).
--
-- Bug (Richard, 20.7.2026): the Admin Directory lists EVERY profile — it reads them via the
-- existing "super-admin reads all profiles" SELECT policy — and offers an Edit sheet on each.
-- But there was NO matching UPDATE policy for a super-admin. The only UPDATE policies on
-- profiles were:
--   * "update own profile"    USING (auth.uid() = id)
--   * "remove kitchen member" USING (kitchen_id = my_kitchen_id_if_admin_only())  -- same kitchen
-- So a Head Admin editing anyone OUTSIDE their own kitchen (a QA account, a member of another
-- kitchen, a teamless user) updated 0 rows — PostgREST returns no error for a 0-row update, so
-- the save LOOKED successful ("Saved.") while nothing actually changed.
--
-- This adds the UPDATE complement to the super-admin SELECT policy, so the platform owner can
-- actually change admin_perms / is_admin on any profile from the Directory. Scope is strictly
-- is_super_admin() (the platform owner) — a Kitchen Admin is NOT a super-admin and is unaffected:
-- they still update only same-kitchen members via "remove kitchen member".
drop policy if exists "super-admin updates all profiles" on profiles;
create policy "super-admin updates all profiles" on profiles
  for update
  using (is_super_admin())
  with check (is_super_admin());
