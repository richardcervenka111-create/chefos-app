-- 149: HACCP cleaning checklist — admin sees WHO checked off each task (Richard, 18.7.:
-- "cleaning check list s tym ze admin vidi kto co odskrtne").
--
-- haccp_checklist_log already records completed_by (a uuid), but nothing ever resolved it to a
-- name for display — same problem check_list_audit_log solved by denormalizing the name at
-- write time instead of joining profiles at read time (this app has no admin-wide "read any
-- profile" policy to join through safely). Mirrors that exact pattern.
--
-- Safe straight to production — additive, nullable column, no backfill, no constraint changes.

alter table haccp_checklist_log add column if not exists completed_by_name text;
