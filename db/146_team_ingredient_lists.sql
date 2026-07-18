-- 146: team-visible ingredient lists (Richard, 18.7.: "člen tímu nevidí nový ingredients
-- list"). db/112 modeled custom lists on My Ingredients — private to their creator. That's
-- wrong for company kitchens: a list the admin makes (parity with recipe projects) must be
-- visible to the whole team. New rule:
--   · READ: everyone in the same kitchen sees the kitchen's lists and the items on them.
--     (In personal mode nothing leaks — a personal kitchen has exactly one member.)
--   · WRITE on the list itself (rename/hide/delete): stays creator-only.
--   · Adding items to a visible list: already works — members insert their OWN is_personal
--     rows carrying that list_id (db/97 insert policy), scoped per-creator by the unique index.

drop policy if exists "own ingredient lists" on ingredient_lists;
create policy "read kitchen ingredient lists" on ingredient_lists
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    or created_by = auth.uid()
  );
create policy "insert own ingredient lists" on ingredient_lists
  for insert with check (created_by = auth.uid());
create policy "update own ingredient lists" on ingredient_lists
  for update using (created_by = auth.uid());
create policy "delete own ingredient lists" on ingredient_lists
  for delete using (created_by = auth.uid());

-- Items on a kitchen's lists become readable to the whole kitchen (they are is_personal rows,
-- which db/97's read policy hid from everyone but their creator). Personal-mode privacy is
-- unaffected: your My Ingredients (list_id null) stay yours alone, and your personal kitchen
-- has no other members anyway.
drop policy if exists "read kitchen ingredients" on ingredients;
create policy "read kitchen ingredients" on ingredients
  for select using (
    (kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and (not is_personal or list_id is not null))
    or created_by = auth.uid()
  );
