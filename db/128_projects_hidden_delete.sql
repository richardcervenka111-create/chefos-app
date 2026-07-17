-- ChefOS — long-press options on Check List PROJECT tiles (Richard, 17.7.), same
-- Rename/Hide/Delete menu as dishes/ingredients/lists already have. projects needed two
-- things for that: a hidden flag, and a DELETE policy (db/94 only created select/insert/
-- update). Deleting a project removes its dishes (and their items via the existing
-- prep_items ON DELETE CASCADE) and its flat tasks — done app-side with an explicit warning.

alter table projects add column if not exists hidden boolean not null default false;

drop policy if exists "delete kitchen projects" on projects;
create policy "delete kitchen projects" on projects
  for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
