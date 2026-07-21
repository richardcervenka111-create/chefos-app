-- Sautero — two missing RLS policies found while auditing everything built this session against
-- the actual database policies (Richard asked "aký SQL ti chýba?" — good catch to check).
-- Both would fail SILENTLY under RLS (Postgres RLS defaults to deny, no error surfaced unless
-- the code checks for it) rather than loudly, so neither would have been obvious until someone
-- actually hit the button in production.
--
-- 1) kitchens has never had an UPDATE policy — it was only ever inserted at creation
--    (34_teams_access_gate.sql) and read for its name. The currency switcher
--    (47_kitchen_currency.sql) is the first feature that ever needs to update a kitchens row
--    itself (`kitchens.display_currency`), and without this, that update would silently no-op
--    for every admin who taps it.
create policy "admin update own kitchen" on kitchens
  for update using (
    exists (select 1 from profiles where id = auth.uid() and kitchen_id = kitchens.id and is_admin)
  );

-- 2) station_icons has select/insert/update policies but no DELETE policy. The section
--    rename feature (app/index.html: saveEditStation()) deletes the old station's icon row
--    before upserting the new one under the renamed station — without this, that delete would
--    silently fail, leaving a stale orphaned icon row behind under the old name.
create policy "delete kitchen station icons" on station_icons
  for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
