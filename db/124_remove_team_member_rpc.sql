-- Sautero — Remove-from-team moved into a SECURITY DEFINER RPC (16.7. neskoro v noci, part 2 of
-- the remove bug). db/121's WITH CHECK fix was necessary but NOT sufficient: live bisection on
-- production (temporarily ALTERing one policy at a time inside a rolled-back transaction)
-- proved the remaining blocker was the "read kitchen teammates" SELECT policy — Postgres
-- required the UPDATED row to be visible to the caller via SELECT policies, and a just-removed
-- member (kitchen_id NULL) is invisible to their ex-admin under every SELECT policy on
-- profiles ("read own profile" no, "read kitchen teammates" no — kitchen_id is NULL, "super-
-- admin reads all" no). Hence "new row violates row-level security policy" even though the
-- UPDATE policy itself passed. Setting kitchen_id to the SAME value worked (row stays
-- visible), which is what made this so confusing.
--
-- Instead of poking another hole into the SELECT policies (an admin has no business reading
-- profiles outside their kitchen), removal becomes a server-side function that checks
-- authorization itself and runs as owner — same established pattern as set_member_assistant
-- (db/109) and claim_company_admin (db/118).

create or replace function remove_team_member(p_member uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_my record;
  v_target_kitchen uuid;
begin
  select kitchen_id, is_admin, admin_perms into v_my from profiles where id = auth.uid();
  if v_my is null or v_my.kitchen_id is null then
    raise exception 'No kitchen on your account';
  end if;
  if not (v_my.is_admin
          or coalesce((v_my.admin_perms->>'company_admin')::boolean, false)
          or coalesce((v_my.admin_perms->>'manage_team')::boolean, false)) then
    raise exception 'Only a kitchen admin can remove team members';
  end if;
  if p_member = auth.uid() then
    raise exception 'You cannot remove yourself';
  end if;
  select kitchen_id into v_target_kitchen from profiles where id = p_member;
  if v_target_kitchen is distinct from v_my.kitchen_id then
    raise exception 'That person is not in your kitchen';
  end if;
  -- Removal = out of the kitchen AND out of "real team member" status (in_team gates the
  -- Company-mode switch, db/116), AND stripped of kitchen-scoped admin perms — they belonged
  -- to a kitchen this person is no longer in. Platform-wide perms granted personally by
  -- Richard (approve_access, create_teams, view_email_contacts) are deliberately kept.
  update profiles set
    kitchen_id = null,
    in_team = false,
    team_join_seen = false,
    admin_perms = coalesce(admin_perms, '{}'::jsonb)
      - 'company_admin' - 'manage_invites' - 'manage_team'
      - 'view_kitchen_reports' - 'assistant' - 'language_audit'
  where id = p_member;
  return true;
end;
$$;
