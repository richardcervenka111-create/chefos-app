-- Sautero — Working Time: exact break log (2026-07-19).
--
-- Richard: the break buttons (+5/+10/+15/+30) silently add a number to one running total —
-- he wants a live "Break" stopwatch that visibly pauses Working Time, and to see EXACTLY when
-- each break happened in the day detail, not just a cumulative minute count.
--
-- This is a pure addition: break_minutes and workingTimeHoursForEntry() are UNTOUCHED. The app
-- keeps front-loading the deduction into break_minutes at the moment a break starts (unchanged
-- behaviour — see app/index.html addWorkingTimeBreak), which already makes the net-hours math
-- pause-then-resume correctly with zero risk to existing calculations, reports, or the db/99
-- kitchen-reports aggregate query that reads break_minutes directly. `breaks` is a parallel,
-- purely additive audit trail — one JSONB array entry per break, {started_at, minutes} — used
-- only to render the live "on break" countdown and the exact per-break times in day detail.
--
-- JSONB chosen over a new child table (Richard's call, 19.7.): no new RLS surface, consistent
-- with the db/158 icons-to-JSONB precedent, and doesn't add a 50th table while Phase 2 of the
-- consolidation is actively trying to shrink the schema.

alter table time_entries add column if not exists breaks jsonb not null default '[]'::jsonb;

-- No RLS changes needed: time_entries already only allows a user to read/write their own rows
-- (db/39_working_time.sql) — nobody else, including teammates or admins, can see these values.
