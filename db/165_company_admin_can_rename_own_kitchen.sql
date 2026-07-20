-- db/165: a Company Admin can rename their OWN kitchen (not just the platform super-admin).
--
-- New flow (Richard, 20.7.2026): when a Head Admin turns on "Company Admin" for a kitchenless
-- user, that user is emailed an Add-Company-style invite and lands on a mandatory "Name your
-- restaurant" step — they name their own kitchen themselves. But the "admin update own kitchen"
-- UPDATE policy on kitchens only allowed profiles.is_admin (the platform super-admin), so a
-- freshly-onboarded Company Admin (company_admin=true, is_admin=false) could not rename their own
-- kitchen — the update hit 0 rows. This broadens it to include the kitchen's own Company Admin.
--
-- Scope is still tight: caller must be a MEMBER of that exact kitchen (profiles.kitchen_id =
-- kitchens.id) AND either the platform super-admin OR its company_admin. A company_admin can only
-- ever rename the one kitchen they belong to — never anyone else's.
drop policy if exists "admin update own kitchen" on kitchens;
create policy "admin update own kitchen" on kitchens
  for update using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
        and profiles.kitchen_id = kitchens.id
        and (profiles.is_admin or (profiles.admin_perms->>'company_admin') = 'true')
    )
  );
