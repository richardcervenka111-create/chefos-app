-- 157: Phase 1 of SUPABASE_CONSOLIDATION_PLAN.md — retire dead tables (Richard approved
-- "chod, začni fázou 1", 19.7.).
--
-- Measured before writing (prod, 19.7.): the app has ZERO call sites for all three targets;
-- live reality differs from the migration-file count:
--   · feedback          — exists in prod, 0 rows (db/98 leftover, superseded by
--                         feedback_reports per db/108)
--   · profile_private   — does NOT exist in prod (db/69 was a draft, never run there)
--   · schedule_entries  — does NOT exist in prod (dropped by db/18 v2 migration)
-- So live prod table count was actually 47, not 49 — two "tables" existed only as create
-- statements in migration files. Staging may still carry them (bootstrap mirrors the files),
-- hence the guarded form below.
--
-- Per the plan's golden rule this is a RENAME, not a DROP: zz_retired_* sits for ≥1 week with
-- instant rollback (rename back), then a follow-up migration drops it (that one will carry
-- the -- DESTRUCTIVE tag + Richard's approval). Renames are reversible — safe class, but the
-- whole consolidation plan runs STAGING FIRST anyway.

do $$
begin
  if exists (select 1 from pg_tables where schemaname='public' and tablename='feedback') then
    alter table public.feedback rename to zz_retired_feedback;
  end if;
  if exists (select 1 from pg_tables where schemaname='public' and tablename='profile_private') then
    alter table public.profile_private rename to zz_retired_profile_private;
  end if;
  if exists (select 1 from pg_tables where schemaname='public' and tablename='schedule_entries') then
    alter table public.schedule_entries rename to zz_retired_schedule_entries;
  end if;
end $$;
