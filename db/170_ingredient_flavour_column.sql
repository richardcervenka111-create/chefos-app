-- 170_ingredient_flavour_column.sql
-- Richard, 23.7.2026 — the "i" ingredient info panel (t13) should be able to STORE a flavour /
-- taste note ("chuť") alongside the existing origin and season, so it shows without needing the
-- on-demand AI. There was no column for it. Purely additive: a nullable text column, no default,
-- nothing else touched. Existing rows keep flavour = NULL until the backfill (db/171+) fills it.
alter table ingredients add column if not exists flavour text;
