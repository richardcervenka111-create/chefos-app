-- ChefOS — recipe SECTIONS scoped per shelf (Richard, 16.7. neskoro večer): opening My Recipes
-- or Company Recipes showed the FULL ChefOS taxonomy (Bakery & Bread, Sushi Basics, 11 sections
-- total) in the Sections picker, even though those shelves have none of those recipes —
-- getCategories() derived its list from every recipe in the kitchen regardless of shelf, and
-- recipe_category_icons (which lets a section exist as a browsable tile before any recipe is
-- tagged with it) was one flat kitchen-wide pool shared by every shelf. Each shelf should start
-- with just Favorites/All and build up its own sections independently from there.
--
-- shelf_scope mirrors the app's own recipeSourceFilter values exactly: 'chefos' | 'mine' |
-- 'company' | a recipe_lists.id (custom project). Existing rows default to 'chefos' — the
-- official ChefOS taxonomy keeps working exactly as it did before this migration.

alter table recipe_category_icons add column if not exists shelf_scope text not null default 'chefos';

-- The old (kitchen_id, category) uniqueness would block "Soups" existing as its own section in
-- both My Recipes and Company Recipes at once — scope is now part of the identity.
do $$
declare
  cname text;
begin
  select conname into cname
  from pg_constraint
  where conrelid = 'recipe_category_icons'::regclass and contype = 'u';
  if cname is not null then
    execute format('alter table recipe_category_icons drop constraint %I', cname);
  end if;
end $$;

alter table recipe_category_icons
  add constraint recipe_category_icons_scope_uidx unique (kitchen_id, category, shelf_scope);
