-- ChefOS — add "question" as a third feedback_reports type (2026-07-15).
--
-- Richard merged the separate Feedback/Bug icons into one dropdown icon with three choices
-- (Feedback / Bug / Question) — the table's check constraint only allowed the first two.

alter table feedback_reports drop constraint if exists feedback_reports_type_check;
alter table feedback_reports add constraint feedback_reports_type_check check (type in ('feedback','bug','question'));
