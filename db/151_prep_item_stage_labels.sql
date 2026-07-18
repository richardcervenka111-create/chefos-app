-- 151: per-ingredient custom TO DO/CHECK/FINISH button labels (Richard, 18.7.: "potrebujem
-- možnosť editovať názov 'TO DO, CHECK, FINISH' v jednotlivých ingredienciach dlhým podržaním
-- tlačidla" — confirmed scope: a custom label for ONE ingredient's button, not a global rename).
--
-- NULL means "use the normal translated TO DO/CHECK/FINISH label" (today's behaviour,
-- unaffected for every existing row). A non-null value overrides just that one item's button
-- text — e.g. an item whose CHECK stage is really "marinating" can show "MARINÁDA" instead.
--
-- Safe straight to production — additive, nullable columns, no backfill, no constraint changes.

alter table prep_items add column if not exists todo_label text;
alter table prep_items add column if not exists check_label text;
alter table prep_items add column if not exists finish_label text;
