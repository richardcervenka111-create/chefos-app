-- Sautero — DRAFT: proper fix for per-person private fields (2026-07-15).
--
-- NOT YET WIRED INTO THE APP. This is a schema-only draft for the correct long-term fix to the
-- bug db/68 just emergency-patched. Column-level GRANT/REVOKE (db/62's approach) can't
-- distinguish "my own row" from "someone else's row" -- it's a blanket per-role permission. The
-- idiomatic fix is a separate table for sensitive fields, with real row-level RLS (owner-only,
-- no teammate policy at all) instead of relying on column privileges.
--
-- Test on chefos-staging first. Once confirmed working there, the app code needs to be updated
-- to read/write profile_private instead of these profiles columns (loadWorkingTimeData,
-- saveContractReview, hasCompletedMyProfile, saveMyProfileGate, saveMyProfileSettings,
-- openMyProfileSettings) -- that code change should happen in the SAME deploy as this migration,
-- not before it (the columns still exist on profiles per db/68's revert, so nothing breaks in
-- the meantime).

create table if not exists profile_private (
  user_id uuid primary key references auth.users(id) on delete cascade,
  contracted_hours_per_week numeric,
  next_vacation_date date,
  contract_notes text,
  contract_advisory_points jsonb,
  age int,
  gender text,
  updated_at timestamptz not null default now()
);

alter table profile_private enable row level security;

create policy "read own private profile" on profile_private
  for select using (user_id = auth.uid());
create policy "insert own private profile" on profile_private
  for insert with check (user_id = auth.uid());
create policy "update own private profile" on profile_private
  for update using (user_id = auth.uid());

-- One-time backfill from the existing profiles columns, once this table is ready to go live.
insert into profile_private (user_id, contracted_hours_per_week, next_vacation_date, contract_notes, contract_advisory_points, age, gender)
select id, contracted_hours_per_week, next_vacation_date, contract_notes, contract_advisory_points, age, gender
from profiles
on conflict (user_id) do nothing;
