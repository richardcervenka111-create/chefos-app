-- Sautero -- Granular admin permissions (Richard, 16.7., bod 1).
--
-- Two kinds of admin from now on:
--   - is_admin (unchanged, db/80): the Sautero super-admin. Richard only. Full reach
--     everywhere, including granting/editing everyone else's admin_perms below.
--   - admin_perms (new): a per-person jsonb bag of DELEGABLE, kitchen-scoped capabilities.
--     Someone with admin_perms set is explicitly NOT is_admin -- "admin kuchyne bude rovnaky
--     profil ako obyčajný, nie admin profil" (a kitchen admin stays an ordinary profile, no
--     "Admin" badge, no super-admin reach) -- they just unlock specific extra buttons.
--
-- Permission keys defined so far (checked with admin_perms->>'key' = 'true' in RLS/app code):
--   manage_invites      -- create/revoke kitchen invite links & QR for their own kitchen
--   manage_team         -- remove team members from their own kitchen
--   language_audit      -- run Language Audit (rewrites Check List names) for their own kitchen
--   view_email_contacts -- view the Email Contacts directory
--   approve_access      -- approve/deny new Sautero access requests (platform-wide -- kept OFF
--                          the "Kitchen Admin" quick-add preset by default; grant individually)
--
-- Also adds profiles.email: the Admin Directory (search by email/name, list every profile)
-- needs to run entirely client-side through the normal Supabase JS client, which can only see
-- the `public` schema -- auth.users (where email actually lives) is never exposed to
-- PostgREST. This denormalizes email onto profiles (standard Supabase pattern for exactly this
-- reason), backfilled once here and kept current going forward by handle_new_user() (updated
-- below to set it at signup, same as it already sets kitchen_id).
--
-- Safe straight to production: additive columns + a backfill of a brand-new column (nothing
-- existing changes) + function replaces (triggers stay attached, no re-creation needed).

alter table profiles add column if not exists admin_perms jsonb not null default '{}'::jsonb;
alter table profiles add column if not exists email text;

update profiles p set email = u.email
from auth.users u
where u.id = p.id and p.email is null;

create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, kitchen_id, email) values (new.id, null, new.email);
  return new;
end;
$$ language plpgsql security definer set search_path = public;
-- the trigger that calls this (from db/34, fixed in db/73) already exists and fires AFTER
-- INSERT on auth.users -- replacing the function body (same exact signature as db/73) is enough.

-- Extends db/80's guard to also cover admin_perms -- otherwise the exact same self-escalation
-- class we found and closed for is_admin (the "update own profile" policy has no column
-- restriction) would just reopen through the new column instead.
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
    raise exception 'is_admin and admin_perms can only be changed by the Sautero super-admin';
  end if;
  return new;
end;
$$;
-- trg_guard_is_admin (db/80) already fires BEFORE UPDATE on profiles for every row change --
-- replacing the function body is enough, the trigger itself doesn't need re-creating.
