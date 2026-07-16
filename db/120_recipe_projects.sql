-- ChefOS — custom recipe collections ("Add Project", Richard, 16.7. bod 8), exact mirror of
-- ingredient_lists (db/112). A project is a named container owned by its creator, private to
-- them, sitting alongside the two fixed shelves (My Recipes / ChefOS, or ChefOS / Company
-- Recipes) on the Recipes picker screen. Its recipes live in the normal `recipes` table with
-- is_personal = true (all existing privacy RLS from db/97 already applies untouched) plus a
-- list_id pointing here — My Recipes = is_personal recipes with list_id NULL, exactly like My
-- Ingredients vs. a custom ingredient list. Long-press on a project tile offers Rename/Hide/
-- Delete via the existing itemContextMenuOverlay ('recipeList' type).

create table if not exists recipe_lists (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  created_by uuid not null references profiles(id),
  name text not null,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);

alter table recipe_lists enable row level security;

create policy "own recipe lists" on recipe_lists
  for all using (created_by = auth.uid()) with check (created_by = auth.uid());

alter table recipes add column if not exists list_id uuid references recipe_lists(id);
grant select (list_id) on recipes to authenticated;
