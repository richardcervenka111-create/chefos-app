-- Sautero — recipe comments visible across kitchens FOR REAL (Richard's live test, 17.7.):
-- db/119 made the RLS allow cross-kitchen reading, but the CLIENT could never build the right
-- query — it looked up sibling copies via `select id from recipes where chefos_master_id = X`,
-- and recipes' own RLS only returns MY kitchen's copy, so comments written against another
-- kitchen's copy id were never fetched even though the policy would have allowed reading them.
--
-- Fix: denormalise. Each comment carries chefos_master_id directly (set on insert by the app,
-- backfilled here), so reading is a single indexed equality — no sibling lookup, no dependence
-- on which recipe rows the reader can see.

alter table recipe_comments add column if not exists chefos_master_id uuid;
create index if not exists recipe_comments_master_idx on recipe_comments(chefos_master_id, created_at);

-- Backfill from the recipe each comment points at.
update recipe_comments c set chefos_master_id = r.chefos_master_id
from recipes r
where r.id = c.recipe_id and c.chefos_master_id is null and r.chefos_master_id is not null;

-- Read policy, simplified: normal visibility via the recipe (unchanged), OR the comment's own
-- master id matches a Sautero-shelf copy in MY kitchen.
drop policy if exists "read comments on visible recipes" on recipe_comments;
create policy "read comments on visible recipes" on recipe_comments
  for select using (
    (
      chefos_master_id is not null
      and exists (
        select 1 from recipes mine
        where mine.chefos_master_id = recipe_comments.chefos_master_id
          and mine.kitchen_id in (select kitchen_id from profiles where id = auth.uid())
      )
    )
    or exists (
      select 1 from recipes r
      where r.id = recipe_comments.recipe_id
        and (
          (r.kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and not r.is_personal)
          or r.created_by = auth.uid()
        )
    )
  );
