-- ChefOS — URGENT fix for a live outage: infinite recursion in profiles RLS (2026-07-13).
--
-- db/53 added two policies ON `profiles` that query `profiles` again inside their own USING
-- clause (aliased p2) to find the caller's kitchen_id / admin status:
--   "read kitchen teammates" -> select kitchen_id from profiles p2 where p2.id = auth.uid()
--   "admin remove kitchen member" -> ...where p2.id = auth.uid() and p2.is_admin
--
-- To resolve that inner subquery, Postgres has to re-apply every SELECT policy on `profiles`
-- to the subquery itself — including "read kitchen teammates" again — which recurses with no
-- stopping point until Postgres raises 42P17 "infinite recursion detected in policy for
-- relation profiles". Confirmed live via a REST probe on 2026-07-13: this doesn't just break
-- direct profiles queries, it breaks EVERY table whose RLS subqueries profiles — recipes,
-- ingredients, prep_items, prep_dishes, access_requests, kitchen_invites insert/update,
-- error_logs, usage_events, check_list_audit_log. Effectively a full app outage since db/53
-- was run.
--
-- Fix: move the "what's my kitchen_id" / "am I admin" lookup into a SECURITY DEFINER function.
-- A SECURITY DEFINER function runs with its owner's privileges, so its internal `select` does
-- NOT re-trigger RLS on profiles — no self-reference, no recursion.

create or replace function my_kitchen_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select kitchen_id from profiles where id = auth.uid()
$$;

create or replace function my_kitchen_id_if_admin()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select kitchen_id from profiles where id = auth.uid() and is_admin
$$;

drop policy if exists "read kitchen teammates" on profiles;
create policy "read kitchen teammates" on profiles
  for select using (
    kitchen_id is not null and kitchen_id = my_kitchen_id()
  );

drop policy if exists "admin remove kitchen member" on profiles;
create policy "admin remove kitchen member" on profiles
  for update using (
    kitchen_id is not null and kitchen_id = my_kitchen_id_if_admin()
  );
