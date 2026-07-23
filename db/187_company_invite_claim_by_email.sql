-- db/187: Add Company must land the invitee as company admin even when the ?invite= link is lost.
--
-- WHAT BROKE (Richard, 24.7.): two people added via Add Company on 23.7. never showed up as admins
-- of their companies. Both had signed up (profiles exist) but with kitchen_id NULL — they were never
-- attached to any kitchen. That state is fatal on its own, because claim_company_admin() (db/118/169)
-- opens with:
--     if not exists (select 1 from profiles where id = auth.uid() and kitchen_id = v_invite.kitchen_id)
--     then return false;
-- i.e. the role can only be granted to someone ALREADY in the kitchen. Getting into the kitchen is
-- joinKitchenViaLink()'s job, and that only runs if the browser still has ?invite=<id> in the URL.
--
-- The whole Add Company flow therefore hangs on one fragile thing: that the magic-link redirect
-- preserves the query string. If Supabase falls back to the Site URL (redirect not allow-listed), or
-- the person opens the app from their home screen / a fresh tab instead of the email link, or simply
-- never taps the final "Join" button, they land as a signed-up user with no kitchen and no way back —
-- and nothing anywhere says so. db/148 fixed the access gate and db/169 fixed the role; this fixes
-- the step between them.
--
-- FIX: remember which email each company invite was for, and let the invitee claim it by email at
-- first login, with no URL involved.
--
-- WHY NOT A COLUMN ON kitchen_invites: that table has a policy literally named "read any invite"
-- (SELECT to any authenticated user). Putting invited_email there would publish every invited
-- address to every logged-in user, and the invite id IS the credential — so the mapping lives in a
-- schema PostgREST does not expose and no client role can reach.

create schema if not exists private;
revoke all on schema private from anon, authenticated;

create table if not exists private.company_invite_emails (
  email       text primary key,
  invite_id   uuid not null references kitchen_invites(id) on delete cascade,
  kitchen_id  uuid not null references kitchens(id) on delete cascade,
  created_at  timestamptz not null default now()
);
revoke all on private.company_invite_emails from anon, authenticated;
alter table private.company_invite_emails enable row level security;  -- unreachable anyway; belt and braces

-- 1) create_company also records the mapping. Same signature and behaviour as db/148 otherwise.
create or replace function create_company(p_name text, p_email text default null)
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
  if p_email is not null and length(trim(p_email)) > 0 then
    insert into access_requests (email, status, reviewed_by, reviewed_at)
      values (lower(trim(p_email)), 'approved', auth.uid(), now());
    -- Newest offer for an address wins: re-running Add Company for the same person (Richard did
    -- exactly that for one of the two) must point them at the company he meant last.
    insert into private.company_invite_emails (email, invite_id, kitchen_id)
      values (lower(trim(p_email)), v_invite_id, v_kitchen_id)
      on conflict (email) do update
        set invite_id = excluded.invite_id, kitchen_id = excluded.kitchen_id, created_at = now();
  end if;
  return query select v_kitchen_id, v_invite_id;
end;
$$;
grant execute on function create_company(text, text) to authenticated;

-- 2) Claim by email — no invite id, no URL. Called by the joining user at first login.
create or replace function claim_company_invite_by_email()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
  v_map   record;
  v_inv   record;
  v_name  text;
begin
  select lower(email) into v_email from auth.users where id = auth.uid();
  if v_email is null then return null; end if;

  -- INVARIANT: this may only ever onboard someone who has no kitchen at all. It can never move an
  -- existing account between kitchens — that is the protection the ?invite= path documents too, and
  -- it is what stops a stale mapping from hijacking an established user.
  if exists (select 1 from profiles where id = auth.uid() and kitchen_id is not null) then
    return null;
  end if;

  select * into v_map from private.company_invite_emails where email = v_email;
  if v_map is null then return null; end if;

  select * into v_inv from kitchen_invites
   where id = v_map.invite_id and grants_company_admin and not revoked and expires_at > now();
  if v_inv is null then return null; end if;

  select name into v_name from kitchens where id = v_map.kitchen_id;
  if v_name is null then return null; end if;

  -- transaction-local GUC: the db/169 guard permits the admin_perms grant only on this validated
  -- path, and only while is_admin stays untouched.
  perform set_config('app.grant_company_admin', 'on', true);
  update profiles set
    kitchen_id   = v_map.kitchen_id,
    in_team      = true,
    account_type = 'company',
    team_join_seen = true,
    pending_company_invite = null,
    admin_perms = coalesce(admin_perms, '{}'::jsonb)
      || '{"company_admin": true, "manage_invites": true, "manage_team": true, "view_kitchen_reports": true}'::jsonb
  where id = auth.uid();

  update kitchen_invites set revoked = true where id = v_map.invite_id;  -- single-use, same as claim_company_admin
  return v_name;
end;
$$;
grant execute on function claim_company_invite_by_email() to authenticated;

-- 3) Backfill the mapping for company invites that are still open, so links already sent keep working.
insert into private.company_invite_emails (email, invite_id, kitchen_id)
select lower(a.email), i.id, i.kitchen_id
from kitchen_invites i
join kitchens k on k.id = i.kitchen_id
join lateral (
  select ar.email from access_requests ar
  where ar.reviewed_at between k.created_at - interval '2 minutes' and k.created_at + interval '2 minutes'
  order by ar.requested_at desc limit 1
) a on true
where i.grants_company_admin and not i.revoked and i.expires_at > now()
on conflict (email) do nothing;
