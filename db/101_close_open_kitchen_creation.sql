-- Sautero — close the old open "create kitchen" hole (Richard, 16.7., follow-up to db/97).
--
-- db/34 (13.7.) let ANY logged-in person create a new kitchen row directly, before Head Admin
-- existed as a concept. db/97 added a properly-gated path (create_team() + create_teams
-- admin_perms) but didn't remove the old open one — Richard confirmed today he wants ONLY
-- people he's personally designated (Head Admin, or someone he grants create_teams) to be able
-- to create kitchens at all.
--
-- Safe to drop: nothing else in the app relies on the open policy. The one legitimate caller
-- (createOwnKitchen() in app/index.html, Richard's own "approved but no kitchen yet" onboarding
-- screen, already gated to isSuperAdmin in the UI) is covered by db/97's
-- "team creators can create kitchens" policy instead, since that policy already allows
-- is_super_admin() — Richard keeps working exactly as before, nobody else can insert directly.

drop policy if exists "create kitchen" on kitchens;
