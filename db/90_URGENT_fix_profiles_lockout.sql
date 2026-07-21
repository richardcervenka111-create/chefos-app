-- Sautero -- URGENT HOTFIX (16.7.): db/86 reintroduced the exact profiles-RLS-recursion bug that
-- caused the 2026-07-13 outage (db/53/db/55), and db/85's new columns were never added to
-- db/62's column-level grant list -- together these locked Richard himself out of his own
-- admin account within hours of running db/85+86. RUN THIS IMMEDIATELY, before anything else.
--
-- Bug 1 (infinite recursion, Postgres error 42P17): db/86's "remove kitchen member" UPDATE
-- policy and the new "super-admin reads all profiles" SELECT policy both query `profiles`
-- directly from inside a policy defined ON `profiles` -- the exact anti-pattern db/55 already
-- found and fixed once (my_kitchen_id_if_admin()). Recreating it re-broke EVERY query against
-- profiles for EVERYONE, not just admins -- Postgres evaluates every permissive policy on a
-- table for every row, so one recursive policy poisons the whole table, including the app's
-- own most basic "who am I" profile fetch on login.
--
-- Bug 2 (permission denied for column): db/62 locked `profiles` down to a specific
-- column allow-list (id, kitchen_id, full_name, role, is_admin, created_at) via a table-wide
-- REVOKE SELECT + column-level GRANT SELECT. db/85 added admin_perms and email but never
-- extended that list -- any select naming either column (including startApp()'s own profile
-- fetch, and every new Admin hub screen) fails outright for every user, every row, admin or
-- not. This alone would explain today's lockout even without bug 1.
--
-- Neither bug ever showed up while testing directly in the Supabase SQL Editor, because that
-- runs as the postgres superuser -- it bypasses both PostgREST's column grants AND RLS
-- entirely. Only the live app (which always queries through the `authenticated` role) was
-- ever going to hit either of these.
--
-- Safe straight to production: this only replaces the two broken policies with the same
-- SECURITY DEFINER pattern db/55 already proved safe, and extends an existing grant list.
-- Nothing here removes access anyone actually had before db/86 ran.

-- ---------- Bug 2 fix: extend db/62's column allow-list ----------
grant select (admin_perms, email) on profiles to authenticated;

-- ---------- Bug 1 fix: same SECURITY DEFINER pattern as db/55's my_kitchen_id_if_admin() ----------
create or replace function my_kitchen_id_if_admin_or_manages_team()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select kitchen_id from profiles
  where id = auth.uid() and (is_admin or (admin_perms->>'manage_team')::boolean)
$$;

create or replace function is_super_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce((select is_admin from profiles where id = auth.uid()), false)
$$;

drop policy if exists "remove kitchen member" on profiles;
create policy "remove kitchen member" on profiles
  for update using (
    kitchen_id is not null and kitchen_id = my_kitchen_id_if_admin_or_manages_team()
  );

drop policy if exists "super-admin reads all profiles" on profiles;
create policy "super-admin reads all profiles" on profiles
  for select using (is_super_admin());
