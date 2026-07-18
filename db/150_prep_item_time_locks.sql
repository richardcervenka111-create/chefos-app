-- 150: Admin can lock an ingredient's per-stage prep time (Richard, 18.7.: "potrebujem aby
-- Admin mal možnosť zamknúť čas jednotlivých ingrediencií pri každom tlačítku - TO DO, CHECK,
-- FINISH").
--
-- Each prep_item already carries 3 independent minute values (todo_minutes/check_minutes/
-- finish_minutes, db/20) that anyone logs and that keep averaging with every new submission
-- (saveAddTimeForItem). A locked stage stops accepting new submissions from non-admins — once
-- an admin has set the authoritative number, staff can no longer drift it, and it's also
-- skipped by the cross-kitchen same-name time sync (db/149's sibling feature,
-- syncPrepItemTimeAcrossKitchen) so a locked duplicate never gets silently overwritten either.
--
-- Safe straight to production — additive, not-null-with-default columns, no backfill needed
-- (default false preserves today's fully-unlocked behaviour for every existing row).

alter table prep_items add column if not exists todo_locked boolean not null default false;
alter table prep_items add column if not exists check_locked boolean not null default false;
alter table prep_items add column if not exists finish_locked boolean not null default false;
