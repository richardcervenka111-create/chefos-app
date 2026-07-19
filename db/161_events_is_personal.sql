-- Sautero — Events: personal/company privacy split (2026-07-19, found during the
-- feature-verification sweep, same class of bug as db/156 order_list_items and db/159
-- projects). events had NO is_personal column at all — an event created while a company
-- member was in "personal" display mode was written straight into the shared kitchen_id
-- bucket and visible to the whole team, exactly the invariant Richard has flagged as
-- CRITICAL twice: personal-mode content must always stay creator-only.
--
-- Creation stays open to any kitchen member (unchanged) — Richard's admin-only-creation rule
-- was specific to Check List projects, never stated for Events.

alter table events add column if not exists is_personal boolean not null default false;

drop policy if exists "read kitchen events" on events;
create policy "read kitchen events" on events for select using (
  (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  or (is_personal and created_by = auth.uid())
);

drop policy if exists "insert kitchen events" on events;
create policy "insert kitchen events" on events for insert with check (
  kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  and ((is_personal and created_by = auth.uid()) or not is_personal)
);

drop policy if exists "update kitchen events" on events;
create policy "update kitchen events" on events for update using (
  (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  or (is_personal and created_by = auth.uid())
);

drop policy if exists "delete kitchen events" on events;
create policy "delete kitchen events" on events for delete using (
  (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  or (is_personal and created_by = auth.uid())
);
