-- DESTRUCTIVE: drops and rebuilds the v1 schedule tables (deliberate v1->v2 rebuild,
-- executed 2026-07-09 before any real schedule data existed; annotated retroactively by the
-- 2026-07-15 health check -- scripts/audit_db.py now requires this acknowledgement).
-- ChefOS — Schedule v2: replaces the v1 sketch with the real shape from Richard's actual
-- work roster (Hotel Schweizerhof Bern AG "Dienstplan Küchenteam"): a grid of staff × date,
-- where each cell holds a shift CODE (e.g. "PJM", "BKFST", "FR") drawn from a fixed dictionary
-- of codes with real start/end times and breaks — not a free-text per-day list.
-- Safe to run even if 16_schedule_schema.sql (the old v1) was already run.
drop table if exists schedule_entries cascade;

create table if not exists shift_codes (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  code text not null,              -- e.g. 'PJM', 'FR'
  label text,                       -- e.g. 'Pass Jax Mittel'
  start_time text,                  -- e.g. '11:30' — kept as text, shifts can have two ranges (split shifts)
  end_time text,                    -- e.g. '20:24'
  second_start_time text,           -- for split shifts, e.g. JTD: 10:30-14:00 AND 17:30-22:24
  second_end_time text,
  break_note text,                  -- e.g. '14:00-14:30' or '10:45-11:15 · 15:00-15:30'
  is_absence boolean not null default false,  -- true for FR/FE/FI/FK/MI/MV/SC — no work hours
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  unique (kitchen_id, code)
);

create table if not exists staff_members (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  name text not null,
  section text,                     -- e.g. 'SKY', 'Bankett', 'Saucier', 'Entremetier', 'Gardemanger', 'Patisserie', 'Frühstück'
  sort_order int not null default 0,
  active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists schedule_assignments (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  staff_id uuid not null references staff_members(id) on delete cascade,
  work_date date not null,
  shift_code_id uuid references shift_codes(id),
  note text,                        -- for one-off annotations, e.g. "Kick Off Trainers 15:00-17:00"
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (staff_id, work_date)
);

alter table shift_codes enable row level security;
alter table staff_members enable row level security;
alter table schedule_assignments enable row level security;

create policy "read kitchen shift codes" on shift_codes for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen shift codes" on shift_codes for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen shift codes" on shift_codes for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen shift codes" on shift_codes for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));

create policy "read kitchen staff" on staff_members for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen staff" on staff_members for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen staff" on staff_members for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen staff" on staff_members for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));

create policy "read kitchen schedule" on schedule_assignments for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen schedule" on schedule_assignments for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen schedule" on schedule_assignments for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen schedule" on schedule_assignments for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
