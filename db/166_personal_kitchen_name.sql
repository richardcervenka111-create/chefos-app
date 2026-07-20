-- db/166: personal_kitchen_name — a per-user display LABEL for a person's own personal space.
--
-- Richard, 21.7.2026: in My Profile, right under the email, every user should see the name of
-- their personal kitchen (what they set on first login). This is purely a display label on the
-- profile — it is NOT a kitchen row, and does NOT touch kitchen_id / account_type / is_personal /
-- team membership / permissions. So nothing about how kitchens, modes, or data separation work
-- changes; a column is simply added and shown.
--
-- Existing accounts are backfilled to 'My Kitchen' (the auto-created personal kitchen's name), so
-- anyone who never set anything shows exactly "My Kitchen", as expected.
alter table profiles add column if not exists personal_kitchen_name text;
alter table profiles alter column personal_kitchen_name set default 'My Kitchen';
update profiles set personal_kitchen_name = 'My Kitchen' where personal_kitchen_name is null;
