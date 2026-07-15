-- ChefOS -- Personal vs Company account type (Richard, 16.7.): every account picks one, once,
-- at login. Controls which Recipe shelves a person sees:
--   personal -> Moje (Mine) + ChefOS
--   company  -> ChefOS + Firemné (Company)
-- ChefOS itself (the shared built-in library, created_by IS NULL) is always visible either way
-- -- only the OTHER shelf (Moje vs Firemné) is exclusive to one account type. Editable later in
-- Settings, not locked in forever.
--
-- "ak sa akýkoľvek účet prihlási" (Richard's wording) means every EXISTING account needs to pick
-- this too, not just new signups -- so this is a mandatory one-time gate (same pattern as the
-- confidentiality/password/My Profile gates: app/index.html's startApp() gate chain), shown on
-- next login until chosen, never again after.
--
-- Defensively grants SELECT on the new column regardless of whatever the current broader grant
-- state on profiles happens to be (history: db/62 restricted it, db/68 emergency-reverted back
-- to a blanket table-wide grant, db/89/90 both added defensive per-column grants on top again).
-- A redundant grant is harmless; a missing one caused today's lockout (db/90) -- always grant
-- explicitly for every new profiles column from now on, belt-and-braces, don't rely on tracing
-- through history to know whether it's already covered.
--
-- Safe straight to production: additive column, no data mutation, no policy changes.

alter table profiles add column if not exists account_type text check (account_type in ('personal','company'));
grant select (account_type) on profiles to authenticated;
