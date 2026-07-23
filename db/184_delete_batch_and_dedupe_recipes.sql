-- 184_delete_batch_and_dedupe_recipes.sql
-- DESTRUCTIVE: removes 55 recipe rows owned by Richard's five accounts, on his explicit
-- instruction (24.7.2026, 00:xx Bern). Two groups:
--   (a) 25 recipes saved in one batch on 23.7. 17:27–17:28 from richard.cervenka@icloud.com
--       (the Apero / Sauces / Side Dishes / Hot Dogs / Soft Serve menu scan) — all of them;
--   (b) 30 leftover duplicate copies from the 22.7. batch-save incident — exactly one copy
--       of each (title, kitchen, personal/company) group is KEPT.
--
-- Which copy survives a duplicate group is deliberate, not "the oldest": the order is
--   public first, then favourited, then noted, then oldest.
-- Checked before writing this: the only two published+favourited copies among the candidates
-- were duplicates, so a naive "keep the oldest" rule would have deleted the copy that is on
-- the public shelf and kept an unpublished twin. With this ordering the target set contains
-- 0 public recipes and 0 favourited recipes.
--
-- Impact check on the 55 targets (run on production before deleting):
--   favorites 0 · recipe_notes 0 · tasks 0 · recipe_comments 0 · recipe_shares 0 · public 0
-- Expected result: Richard's own recipe count 161 -> 106.
--
-- REVERSIBLE: every deleted row is copied into backup.recipes_20260724 first. That schema is
-- NOT in PostgREST's exposed schemas, so the anon key cannot reach it; rights are revoked from
-- anon/authenticated and RLS is on with no policies as a second and third lock.
-- To restore everything:  insert into recipes select * from backup.recipes_20260724;

create schema if not exists backup;
revoke all on schema backup from anon, authenticated;

-- 1. Snapshot the rows that are about to go.
create table if not exists backup.recipes_20260724 as
with mine as (
  select r.* from recipes r join profiles p on p.id = r.created_by
  where lower(p.email) in ('richard.cervenka@icloud.com','richard.cervenka111@gmail.com',
    'chefos@protonmail.com','sautero_android@proton.me','sautero.guardian@atomicmail.io')
),
batch as (
  select m.id from mine m join profiles p on p.id = m.created_by
  where lower(p.email) = 'richard.cervenka@icloud.com'
    and (m.created_at at time zone 'Europe/Zurich') >= timestamp '2026-07-23 15:00'
    and (m.created_at at time zone 'Europe/Zurich') <  timestamp '2026-07-24 00:00'
),
ranked as (
  select m.id, row_number() over (
    partition by lower(trim(m.title)), m.kitchen_id, coalesce(m.is_personal,false)
    order by coalesce(m.is_public,false) desc,
             (exists(select 1 from favorites f where f.recipe_id = m.id)) desc,
             (exists(select 1 from recipe_notes n where n.recipe_id = m.id)) desc,
             m.created_at, m.id) rn
  from mine m
),
dupes as (select id from ranked where rn > 1),
targets as (select id from batch union select id from dupes)
select r.* from recipes r where r.id in (select id from targets);

revoke all on backup.recipes_20260724 from anon, authenticated;
alter table backup.recipes_20260724 enable row level security;

-- 2. DESTRUCTIVE: delete exactly the snapshotted rows — nothing is re-derived here, so the
--    delete can never widen beyond what was backed up.
delete from recipes where id in (select id from backup.recipes_20260724);
