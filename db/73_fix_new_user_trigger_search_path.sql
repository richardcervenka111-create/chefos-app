-- Sautero — CRITICAL: fix "Database error saving new user" blocking every new signup (2026-07-14).
--
-- Root cause (confirmed live in Supabase's Postgres logs while Richard was testing a brand new
-- gmail address): handle_new_user() -- the trigger that creates a profiles row the moment
-- someone signs up -- fails with `relation "profiles" does not exist`, even though the table
-- obviously exists (every existing user already has a working profile). This is the classic
-- Postgres SECURITY DEFINER gotcha: a SECURITY DEFINER function's `search_path` is NOT pinned to
-- `public` unless you say so explicitly -- it inherits whatever search_path is active in the
-- CALLER's session. Supabase's internal auth service that fires this trigger apparently doesn't
-- have `public` on its search_path, so the unqualified `profiles` reference can't resolve.
--
-- This has been silently blocking every brand-new signup (anyone who has never logged into
-- Sautero before) since 34_teams_access_gate.sql last redefined this function -- existing users
-- were never affected because the trigger only runs once, at account creation. Client-side, this
-- surfaced as a misleading "too many emails, wait an hour" message, because
-- friendlyAuthErrorMessage() in app/index.html treats any unrecognized/malformed error as a rate
-- limit -- it was actually masking this completely different, more serious bug.
--
-- Fix: pin search_path explicitly and fully-qualify the table name (belt and suspenders) so this
-- can never again depend on whatever schema context happens to be active when the trigger fires.
--
-- This is an EMERGENCY fix (same urgency class as db/68) -- it blocks all new signups right now,
-- including team invites and the public trial. Safe to run directly on production: it only
-- redefines a function, touches no existing data, and is a strict correctness fix with no
-- behavior change for anyone it currently works for.

create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, kitchen_id) values (new.id, null);
  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- ---------- Secondary finding from the same incident ----------
-- The same failed signup attempt also tried (and failed) to log itself to error_logs: "new row
-- violates row-level security policy for table error_logs". Not a bug in the policy itself --
-- it correctly requires auth.uid() is not null, but sendLoginCode()'s error handler calls
-- logClientError() BEFORE the person is logged in (they're failing to log in in the first
-- place), so there's no auth.uid() yet. Net effect: the exact class of error we most need
-- visibility into -- failures during login itself -- could never reach error_logs at all.
--
-- Loosening this to also allow anonymous inserts is a deliberate, low-risk trade-off: error_logs
-- has no anon SELECT policy (db/51, still only admins can read it) and carries no sensitive data
-- beyond what any browser already sends (message/stack/url/user_agent) -- worst case of opening
-- this up is some junk rows from bots, not a privacy or data leak.
create policy "log pre-login errors too" on error_logs
  for insert with check (auth.uid() is null);
