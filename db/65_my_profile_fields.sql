-- Sautero — "My Profile" mandatory first-login fields (2026-07-15).
--
-- Richard: every first-time user must fill in their name, age, and gender before they can use
-- the app ("registrácia" / My Profile). full_name already exists on profiles (db/01_schema.sql);
-- this adds the two missing fields.
--
-- Same privacy boundary as the contract fields (db/62): these are personal, not professional —
-- teammates should not casually browse each other's age/gender. The existing "read kitchen
-- teammates" RLS policy (db/55) is row-level only, so if db/62's column-level GRANT/REVOKE has
-- been run, add age/gender to the EXCLUDED list there too (not included in the teammate-visible
-- column grant below on purpose).

alter table profiles add column if not exists age int;
alter table profiles add column if not exists gender text;

-- If db/62 has already been run on this database, re-run its grant with age/gender still
-- excluded (harmless if db/62 hasn't run yet — this only touches columns that already exist).
do $$
begin
  if exists (select 1 from information_schema.columns where table_name = 'profiles' and column_name = 'age') then
    revoke select on profiles from authenticated;
    grant select (
      id, kitchen_id, full_name, role, is_admin, created_at
    ) on profiles to authenticated;
  end if;
end $$;
