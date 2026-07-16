-- ChefOS — ChefOS-shelf recipe comments, shared across every kitchen (Richard, 16.7. bod 6).
--
-- Root cause: db/87 seeds every kitchen with its OWN physical copy of each ChefOS library
-- recipe (a fresh gen_random_uuid() row per kitchen, all other columns identical). recipe_
-- comments.recipe_id points at one specific kitchen's copy, so a comment posted from kitchen A
-- was never visible from kitchen B's copy of "the same" recipe, even though to Richard and every
-- chef these are conceptually the SAME recipe. Personal/Company recipes are correctly excluded
-- from this — those really are distinct per-author recipes, comments there should stay scoped
-- exactly as before.
--
-- Fix: a stable chefos_master_id shared by every kitchen's copy of the same underlying ChefOS
-- recipe. Comments become visible/postable across the whole "family" of copies sharing a
-- master_id, not just the one exact row. Applies going forward too — any brand-new recipe
-- created directly on the ChefOS shelf gets a fresh master_id the moment it's saved, and
-- seed_new_kitchen_recipes() (db/87) already copies every column except id/kitchen_id/
-- created_by/created_at/updated_at dynamically, so it carries chefos_master_id verbatim into
-- every new kitchen's copy for free — no changes needed there.

alter table recipes add column if not exists chefos_master_id uuid;
grant select (chefos_master_id) on recipes to authenticated;

-- Backfill: every existing ChefOS-shelf row (created_by is null, not is_personal), grouped by
-- title — db/87's copies are otherwise byte-identical to their source, so title is a reliable
-- key for "the same recipe" within this scope. Personal/Company rows are untouched (stay NULL).
with groups as (
  select title, gen_random_uuid() as master_id
  from recipes
  where created_by is null and not is_personal
  group by title
)
update recipes r set chefos_master_id = g.master_id
from groups g
where r.title = g.title and r.created_by is null and not r.is_personal;

-- Any ChefOS-shelf recipe created from now on (this reference kitchen or any other) gets its
-- own master_id automatically, the instant it's saved — so comments work immediately, even
-- before it's ever copied anywhere.
create or replace function assign_chefos_master_id()
returns trigger as $$
begin
  if new.chefos_master_id is null and new.created_by is null and not new.is_personal then
    new.chefos_master_id := gen_random_uuid();
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists before_insert_assign_chefos_master_id on recipes;
create trigger before_insert_assign_chefos_master_id
  before insert on recipes
  for each row execute function assign_chefos_master_id();

-- Comments visible if the recipe they're attached to is visible to me the normal way (personal/
-- company, unchanged), OR it's a ChefOS-shelf recipe and MY kitchen has its own copy sharing the
-- same chefos_master_id (i.e. "the same ChefOS recipe" also exists on my shelf).
drop policy if exists "read comments on visible recipes" on recipe_comments;
create policy "read comments on visible recipes" on recipe_comments
  for select using (
    exists (
      select 1 from recipes r
      where r.id = recipe_comments.recipe_id
        and (
          (r.kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and not r.is_personal)
          or r.created_by = auth.uid()
          or (
            r.chefos_master_id is not null
            and exists (
              select 1 from recipes mine
              where mine.chefos_master_id = r.chefos_master_id
                and mine.kitchen_id in (select kitchen_id from profiles where id = auth.uid())
            )
          )
        )
    )
  );

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
        )
    )
  );
-- "delete own comments" (db/104) is untouched — deleting was never scoped by recipe visibility.
