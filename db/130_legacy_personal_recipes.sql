-- ChefOS — "My Recipes" must NEVER show company saves (Richard, 17.7.: recipe saved in
-- company mode kept appearing on the personal shelf).
--
-- Root cause: the shelf predicate had a legacy exception — in PERSONAL mode it showed ALL of
-- your authored recipes regardless of is_personal, so pre-db/97 rows (saved before the flag
-- existed, all is_personal=false) wouldn't vanish. But the same exception leaked company-mode
-- saves onto the personal shelf for anyone who toggles modes.
--
-- Fix: the app predicate is now strictly is_personal=true in both modes, and the legacy rows
-- get repaired HERE in the data instead. Safe classification: company mode is gated to real
-- team members (db/116 — kitchen admin, company_admin perm, or in_team), so any authored
-- non-personal recipe whose author is NOT a team member can only have been meant as personal.
-- Team members' legacy rows stay on the Company shelf (still visible, just not personal).

update recipes r set is_personal = true
where r.created_by is not null
  and r.is_personal = false
  and exists (
    select 1 from profiles p
    where p.id = r.created_by
      and not coalesce(p.is_admin, false)
      and not coalesce(p.in_team, false)
      and not coalesce((p.admin_perms->>'company_admin')::boolean, false)
  );
