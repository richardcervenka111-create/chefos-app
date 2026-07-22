-- db/169: Add Company invite grants the company-admin ROLE on join (Richard, 22.7. — "ak pridám
-- niekoho cez Add Company a človek nikdy nebol v appke, pustí ho dnu ale iba ako member").
--
-- Root cause: claim_company_admin() (db/118) writes admin_perms, but it is called by the JOINING
-- user (not the super-admin). The db/85 guard (guard_is_admin_changes) blocks ANY non-super-admin
-- from changing is_admin OR admin_perms — so the write raises "is_admin and admin_perms can only be
-- changed by the Sautero super-admin", the claim returns an error, and the person stays a plain
-- member. db/148 fixed getting them IN past the access gate; this fixes getting the ROLE applied.
--
-- Fix: claim_company_admin (SECURITY DEFINER, which already validates the invite + kitchen
-- membership + empty seat) sets a TRANSACTION-LOCAL GUC before the update; the guard permits an
-- admin_perms change while that GUC is on — but ONLY when is_admin is unchanged, so this path can
-- NEVER grant the super-admin flag, only the company_admin bundle. The GUC is transaction-scoped
-- and set solely inside this SECURITY DEFINER function; a client's own profiles UPDATE (via
-- PostgREST) can't set it, so the self-escalation class db/80/85 closed stays closed.
--
-- Safe straight to production — two function-body redefinitions only, no schema/data/RLS changes.

-- 1) The guard: allow the trusted claim_company_admin path (GUC on) to change admin_perms only.
create or replace function guard_is_admin_changes()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if (new.is_admin is distinct from old.is_admin) or (new.admin_perms is distinct from old.admin_perms) then
    if auth.uid() is null then
      return new; -- SQL editor / service role: allowed (Richard's manual operations)
    end if;
    if auth.uid() in (select id from auth.users where lower(email) = 'richard.cervenka@icloud.com') then
      return new; -- the super-admin himself, acting from inside the app
    end if;
    -- Trusted claim_company_admin path: it sets this transaction-local GUC AFTER validating the
    -- invite. It may grant the company_admin perms bundle, but is_admin must stay untouched — so a
    -- company admin can never become the platform super-admin through here.
    if current_setting('app.grant_company_admin', true) = 'on'
       and new.is_admin is not distinct from old.is_admin then
      return new;
    end if;
    raise exception 'is_admin and admin_perms can only be changed by the Sautero super-admin';
  end if;
  return new;
end;
$$;

-- 2) claim_company_admin: flip the GUC on right before the admin_perms write. Same body as db/118
--    otherwise (fresh invite always works; a burnt one only while the company-admin seat is empty).
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
    where id = p_invite and grants_company_admin;
  if v_invite is null then
    return false;
  end if;
  if not exists (select 1 from profiles where id = auth.uid() and kitchen_id = v_invite.kitchen_id) then
    return false;
  end if;
  if (v_invite.revoked or v_invite.expires_at <= now())
     and exists (
       select 1 from profiles
       where kitchen_id = v_invite.kitchen_id
         and (admin_perms->>'company_admin')::boolean is true
     ) then
    return false;
  end if;
  -- transaction-local: only this validated path may grant company_admin perms (see the guard above)
  perform set_config('app.grant_company_admin', 'on', true);
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

-- Verify: as a freshly-joined invitee, claim_company_admin(<their invite>) should return true and
-- their profiles.admin_perms should carry company_admin/manage_invites/manage_team/view_kitchen_reports,
-- while is_admin stays false. A direct client UPDATE setting admin_perms must still raise.
