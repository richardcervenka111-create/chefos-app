-- ChefOS — real team membership flag (Richard, 16.7. večer): switching to a Company account
-- is no longer open to anyone — only to people who ACTUALLY joined a team (via an invite
-- link/email or a team join code) or hold a kitchen-admin role. profiles.in_team records the
-- real join event; a personal account's auto-created solo kitchen never sets it.

alter table profiles add column if not exists in_team boolean not null default false;
grant select (in_team) on profiles to authenticated;

-- Joining via a team join code = real membership.
create or replace function join_team_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_kitchen_id uuid;
begin
  select id into v_kitchen_id from kitchens
    where join_code_hash = encode(digest(upper(trim(p_code)), 'sha256'), 'hex');
  if v_kitchen_id is null then
    raise exception 'Invalid code';
  end if;
  update profiles set kitchen_id = v_kitchen_id, in_team = true where id = auth.uid();
  return v_kitchen_id;
end;
$$;

-- Accepting an Add Company invite = real membership (as its admin).
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
  update profiles set
    admin_perms = coalesce(admin_perms, '{}'::jsonb)
      || '{"company_admin": true, "manage_invites": true, "manage_team": true, "view_kitchen_reports": true}'::jsonb,
    team_join_seen = true,
    in_team = true
    where id = auth.uid();
  update kitchen_invites set revoked = true where id = p_invite;
  return true;
end;
$$;

-- Joining via a normal kitchen invite happens through a client-side profiles update
-- (joinKitchenViaLink) — RLS "update own profile" already lets the person set their own
-- in_team alongside kitchen_id, no new grant needed (whole-row update policy from db/34).

-- Backfill: anyone already sharing a kitchen with at least one other person genuinely joined
-- something — solo kitchens stay in_team = false.
update profiles p set in_team = true
where p.kitchen_id is not null
  and (select count(*) from profiles m where m.kitchen_id = p.kitchen_id) > 1;
