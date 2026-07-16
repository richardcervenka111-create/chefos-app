-- ChefOS — sharing ingredient lists with chef friends (Richard, 16.7. večer, bod 4). Same
-- opt-in model as Share My Recipes (db/89): the owner flips a per-list Share toggle
-- (long-press the list tile), and connected friends (chef_connections) can then READ that
-- list and its items — never edit, never see anything not explicitly shared. The two fixed
-- shelves (ChefOS, My Ingredients) are not shareable; only custom lists (db/112).

alter table ingredient_lists add column if not exists shared boolean not null default false;

create policy "read connected shared lists" on ingredient_lists
  for select using (
    shared and exists (
      select 1 from chef_connections c
      where (c.user_a = auth.uid() and c.user_b = ingredient_lists.created_by)
         or (c.user_b = auth.uid() and c.user_a = ingredient_lists.created_by)
    )
  );

-- Items of a shared list become readable to the same connected friends — one extra OR'd
-- SELECT policy on ingredients, additive to everything from db/97/db/105.
create policy "read items of connected shared lists" on ingredients
  for select using (
    list_id is not null and exists (
      select 1 from ingredient_lists l
      join chef_connections c on (
        (c.user_a = auth.uid() and c.user_b = l.created_by)
        or (c.user_b = auth.uid() and c.user_a = l.created_by)
      )
      where l.id = ingredients.list_id and l.shared
    )
  );
