-- ChefOS — Working Time / contract review: the AI note is now a list of individual points
-- (not one paragraph), so each one can be checked off as "handled" separately. Kept
-- `contract_notes` (the old single-text column) untouched for anyone who already scanned a
-- contract before this change — it still displays, just without per-point checkboxes, until
-- they re-scan.
alter table profiles add column if not exists contract_advisory_points jsonb;
