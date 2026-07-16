-- ChefOS — Add Company + kitchen main-admin tier + assistants (Richard, 16.7., bod 5).
--
-- New hierarchy:
--   Richard (Head Admin) → "Add Company": creates the company's kitchen + a SINGLE-USE invite
--   for exactly one person, who on accepting becomes that kitchen's MAIN ADMIN
--   (admin_perms.company_admin — plus manage_invites/manage_team/view_kitchen_reports so they
--   can actually run their kitchen day one).
--   Kitchen main admin → sees "Create Team" (join codes; the tile moves OFF Richard's own
--   account per his explicit wording) and can mark any member of their kitchen as an
--   ASSISTANT (admin_perms.assistant — a designation the app can hang capabilities on later).
--
-- Single-use is enforced server-side: claim_company_admin() revokes the invite in the same
-- statement that grants the role — a second person opening the same link still joins nothing
-- (the invite is already revoked by then, renderTeamGate treats it as expired).

alter table kitchen_invites add column if not exists grants_company_admin boolean not null default false;
grant select (grants_company_admin) on kitchen_invites to authenticated;

-- Head Admin only: create the company's kitchen + its one-shot main-admin invite in one go.
create or replace function create_company(p_name text)
returns table(kitchen_id uuid, invite_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kitchen_id uuid;
  v_invite_id uuid;
begin
  if not is_super_admin() then
    raise exception 'Not authorized';
  end if;
  insert into kitchens (name, created_by) values (p_name, auth.uid()) returning id into v_kitchen_id;
  insert into kitchen_invites (kitchen_id, created_by, grants_company_admin)
    values (v_kitchen_id, auth.uid(), true)
    returning id into v_invite_id;
  return query select v_kitchen_id, v_invite_id;
end;
$$;
grant execute on function create_company(text) to authenticated;

-- Called by the app right after someone joins via a ?invite= link that carries the flag.
-- Verifies everything server-side (the flag, expiry, revocation, that the caller really is in
-- that kitchen now) — the client merely asks, this decides.
create or replace function claim_company_admin(p_invite uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite record;
begin
  select * into v_invite from kitchen_invites
    where id = p_invite and grants_company_admin and not revoked and expires_at > now();
  if v_invite is null then
    return false;
  end if;
  if not exists (select 1 from profiles where id = auth.uid() and kitchen_id = v_invite.kitchen_id) then
    return false;
  end if;
  update profiles set admin_perms = coalesce(admin_perms, '{}'::jsonb)
    || '{"company_admin": true, "manage_invites": true, "manage_team": true, "view_kitchen_reports": true}'::jsonb
    where id = auth.uid();
  update kitchen_invites set revoked = true where id = p_invite;
  return true;
end;
$$;
grant execute on function claim_company_admin(uuid) to authenticated;

-- Kitchen main admin designates/removes assistants among their own kitchen's members.
-- SECURITY DEFINER because members can't update each other's profiles rows via RLS — the
-- authorization is this function's own explicit check, nothing broader.
create or replace function set_member_assistant(p_member uuid, p_on boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller record;
  v_member record;
begin
  select * into v_caller from profiles where id = auth.uid();
  if v_caller is null or not (v_caller.is_admin or (v_caller.admin_perms->>'company_admin')::boolean is true) then
    raise exception 'Not authorized';
  end if;
  select * into v_member from profiles where id = p_member;
  if v_member is null or v_member.kitchen_id is distinct from v_caller.kitchen_id then
    raise exception 'Not a member of your kitchen';
  end if;
  update profiles set admin_perms = coalesce(admin_perms, '{}'::jsonb)
    || jsonb_build_object('assistant', p_on)
    where id = p_member;
end;
$$;
grant execute on function set_member_assistant(uuid, boolean) to authenticated;

-- Kitchen main admins can mint/regenerate their kitchen's join codes and create additional
-- teams (multi-location restaurants) — extends db/97's checker to the new role.
create or replace function _is_team_creator()
returns boolean
language sql
security definer
set search_path = public
as $$
  select is_super_admin() or exists (
    select 1 from profiles
    where id = auth.uid()
      and ((admin_perms->>'create_teams')::boolean is true
        or (admin_perms->>'company_admin')::boolean is true)
  );
$$;
