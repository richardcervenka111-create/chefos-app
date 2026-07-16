-- ChefOS — fix "Could not remove: new row violates row-level security policy for table
-- 'profiles'" (Richard, 16.7. neskoro večer bod 1).
--
-- Root cause: db/90's "remove kitchen member" policy only declared a USING clause —
--   for update using (kitchen_id is not null and kitchen_id = my_kitchen_id_if_admin_or_manages_team())
-- Postgres defaults an UPDATE policy's WITH CHECK to the SAME expression as USING when none is
-- given explicitly. That default requires the RESULTING row to still satisfy
-- "kitchen_id is not null" — but removeTeamMember() sets kitchen_id to NULL, which is the whole
-- point of "remove". Every remove attempt failed this self-contradictory check.
--
-- Fix: an explicit WITH CHECK that allows the result to become NULL (removed) OR stay in the
-- admin's own kitchen (covers any other update this policy might ever cover). USING is
-- untouched — who you're allowed to target doesn't change, only what the result may look like.

drop policy if exists "remove kitchen member" on profiles;
create policy "remove kitchen member" on profiles
  for update using (
    kitchen_id is not null and kitchen_id = my_kitchen_id_if_admin_or_manages_team()
  )
  with check (
    kitchen_id is null or kitchen_id = my_kitchen_id_if_admin_or_manages_team()
  );
