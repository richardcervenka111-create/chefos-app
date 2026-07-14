-- ChefOS — restrict contract/pay-adjacent profile columns to the row owner only (2026-07-14).
--
-- Found while restyling the "AI note on your contract" screen (Richard's request: teammates must
-- never see this about each other). The "read kitchen teammates" policy on profiles (db/55) is a
-- ROW-level RLS policy -- it grants full-row SELECT to every teammate in the same kitchen. RLS in
-- Postgres does not restrict individual columns, so any teammate could directly query `profiles`
-- and read someone else's contract_notes, contract_advisory_points, contracted_hours_per_week, or
-- next_vacation_date. The app itself never does this today (every `profiles` select in
-- app/index.html for a teammate only ever asks for id/full_name/is_admin/kitchen_id -- checked),
-- but "the app happens not to ask for it" is not a real security boundary. RLS + column privileges
-- together are.
--
-- Fix: Postgres column-level GRANT/REVOKE layers on top of row-level policies -- a column REVOKE
-- still applies even when a row policy would allow the row. Revoke table-wide SELECT from
-- `authenticated`, then re-grant it only for the columns teammates legitimately need to see (name,
-- role, admin flag, kitchen). The existing "own row" policies are untouched, so everyone can still
-- read/write every column of their OWN profile, including the contract fields -- this only removes
-- OTHER teammates' ability to read those columns on someone else's row.
--
-- TEST ON chefos-staging FIRST. profiles is the same table that caused the db/53/55 outage --
-- verify the My Team member list and admin screens still work before running this on production.

revoke select on profiles from authenticated;

grant select (
  id, kitchen_id, full_name, role, is_admin, created_at
) on profiles to authenticated;

-- Deliberately excluded from the teammate-visible column list (readable only on one's own row,
-- via the existing "own row" RLS policies):
--   contracted_hours_per_week, next_vacation_date, contract_notes, contract_advisory_points
