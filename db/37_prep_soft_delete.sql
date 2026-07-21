-- Sautero — "Delete" on a Check List item/dish/section now soft-deletes (recoverable) instead
-- of permanently removing the row, after Richard accidentally deleted/hid real data with no
-- way to undo it. Separate flag from `hidden` (36_prep_hidden.sql) — hidden = "skip today, on
-- purpose, always reversible"; deleted = "meant to remove this, but mistakes happen too."
alter table prep_dishes add column if not exists deleted boolean not null default false;
alter table prep_items add column if not exists deleted boolean not null default false;
