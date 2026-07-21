-- Sautero — removal from a team must NOT lock the person out of Sautero entirely (Richard,
-- 16.7. ~23:40): db/124 left the removed member with kitchen_id NULL, which renderTeamGate
-- treats as "no access — invite-only". Correct behavior: they lose the COMPANY kitchen only,
-- and immediately get their own fresh personal "My Kitchen" (the kitchens-insert triggers from
-- db/74/db/87 seed the standard Sautero ingredient + recipe shelves automatically), flipped to
-- personal account mode. Their personal (is_personal) recipes/ingredients follow created_by,
-- not kitchen_id (db/97), so nothing of their own is lost in the move.

create or replace function remove_team_member(p_member uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_my record;
  v_target_kitchen uuid;
  v_new_kitchen uuid;
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
  -- Their own fresh solo kitchen — same standard start as any new personal signup (db/110).
  insert into kitchens (name, created_by) values ('My Kitchen', p_member) returning id into v_new_kitchen;
  update profiles set
    kitchen_id = v_new_kitchen,
    account_type = 'personal',
    in_team = false,
    team_join_seen = false,
    admin_perms = coalesce(admin_perms, '{}'::jsonb)
      - 'company_admin' - 'manage_invites' - 'manage_team'
      - 'view_kitchen_reports' - 'assistant' - 'language_audit'
  where id = p_member;
  return true;
end;
$$;

-- ---------- One-off repair: richard.cervenka111@gmail.com was removed under db/124's rules
-- (kitchen_id NULL → locked out at the gate). Give the account its own kitchen the same way
-- the function above now does. Idempotent: skips anyone who already has a kitchen. ----------
do $$
declare
  v_member uuid;
  v_new_kitchen uuid;
begin
  select p.id into v_member
  from profiles p
  where p.id = (select id from auth.users where lower(email) = 'richard.cervenka111@gmail.com')
    and p.kitchen_id is null;
  if v_member is null then
    return;
  end if;
  insert into kitchens (name, created_by) values ('My Kitchen', v_member) returning id into v_new_kitchen;
  update profiles set
    kitchen_id = v_new_kitchen,
    account_type = 'personal',
    in_team = false,
    team_join_seen = false
  where id = v_member;
end $$;
