-- Sautero — extends ingredients with two new filterable dimensions Richard asked for, scoped
-- down from the full "master ingredient database" spec to what's actually needed for the
-- Ingredients season/storage-type filter (not the full 20k-row/multi-table architecture —
-- that's a separate, paused decision). Adds columns only; the data fill (existing 535
-- ingredients + ~765 new ones to reach ~1300) comes from the background research pass and
-- lands in db/31_ingredients_expansion.sql.
alter table ingredients add column if not exists storage_type text
  check (storage_type in ('Dry Storage','Refrigerated','Freezer','Room Temperature'));
alter table ingredients add column if not exists seasons text[] not null default '{}';
  -- subset of {'Spring','Summer','Autumn','Winter'} — empty array means year-round/not seasonal
