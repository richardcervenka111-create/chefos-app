-- ChefOS — Working Time: real check-in/check-out time tracking. Overtime is a fixed 8h/day
-- threshold (Richard's own rule — "ak človek pracuje viac ako osem hodín v daný deň" — not
-- tied to the contracted weekly hours below).
--
-- "Next day off" and "contracted hours" live directly on profiles as simple, per-person,
-- manually-set fields rather than being derived from the existing Schedule roster: the
-- Schedule's `staff_members` rows (18_schedule_v2_schema.sql) are just names entered by a
-- manager, with no link to an actual login account, so there's no reliable way today to match
-- "the person currently logged in" to "a row in that roster." Simpler and correct now; wiring
-- staff_members to profiles.id is a separate future project if the roster needs to drive this.
create table if not exists time_entries (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  user_id uuid not null references auth.users(id),
  check_in timestamptz not null,
  check_out timestamptz,
  break_minutes int not null default 0,
  created_at timestamptz not null default now()
);
alter table time_entries enable row level security;

create policy "read own time entries" on time_entries
  for select using (user_id = auth.uid());
create policy "insert own time entries" on time_entries
  for insert with check (user_id = auth.uid() and kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update own time entries" on time_entries
  for update using (user_id = auth.uid());
create policy "delete own time entries" on time_entries
  for delete using (user_id = auth.uid());

alter table profiles add column if not exists contracted_hours_per_week numeric;
alter table profiles add column if not exists next_vacation_date date;
alter table profiles add column if not exists contract_notes text;
