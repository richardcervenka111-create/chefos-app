-- ChefOS — commenting on PUBLIC recipes (Richard's live test, 17.7.: gmail/icloud accounts got
-- "new row violates row-level security policy for table recipe_comments" on a public recipe).
--
-- db/131's header claimed comment INSERT would work automatically because db/104's policy
-- delegated visibility to recipes' own RLS ("recipe_id in (select id from recipes)"). That was
-- true of db/104 — but db/119 later REPLACED that insert policy with one that enumerates the
-- allowed cases explicitly (own kitchen non-personal, or own recipe), so public recipes from
-- other kitchens fail the check. Same lesson as the read policy: once visibility is enumerated
-- explicitly somewhere, every new visibility class has to be added there by hand.

drop policy if exists "comment on visible recipes" on recipe_comments;
create policy "comment on visible recipes" on recipe_comments
  for insert with check (
    created_by = auth.uid()
    and exists (
      select 1 from recipes r
      where r.id = recipe_comments.recipe_id
        and (
          (r.kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and not r.is_personal)
          or r.created_by = auth.uid()
          or r.is_public
        )
    )
  );
