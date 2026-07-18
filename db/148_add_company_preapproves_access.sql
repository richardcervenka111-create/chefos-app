-- 148: Add Company invite must grant admin functions immediately (Richard, 18.7.: "hneď musí
-- mať funkcie ako admin po kliknutí na link a vyplnení všetkých polí").
--
-- Root cause: create_company() (db/109) never touched access_requests. A brand-new person who
-- has no kitchen_id yet always goes through renderTeamGate() first, which checks
-- access_requests and blocks anyone without status='approved' behind "Waiting for approval" —
-- the closed-trial gate (db/34/81). Since Add Company never pre-approved the invited email,
-- the invitee got stuck on that screen and never even reached the "You're invited → Join"
-- step that calls claim_company_admin(), no matter how fast they filled in the signup form.
--
-- Fix: create_company() now takes the invited email and inserts an already-approved
-- access_requests row for it in the same transaction as the kitchen + invite. renderTeamGate()
-- always reads the MOST RECENT row per email (order by requested_at desc limit 1), so this row
-- wins regardless of any earlier pending/denied history for that address.
--
-- Safe straight to production — function redefinition only (adds one optional trailing
-- parameter with a default, per Postgres CREATE OR REPLACE rules), no schema/data changes,
-- no RLS policy changes. Existing callers passing only p_name keep working unchanged.

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
  end if;
  return query select v_kitchen_id, v_invite_id;
end;
$$;
grant execute on function create_company(text, text) to authenticated;
