-- 147: team-visible recipe projects (Richard, 18.7.: "pridaj do receptov rovnakú funkciu ako
-- v ingredienciách — zdieľať recepty v danom projekte"). Exact mirror of db/146 for
-- ingredient lists. recipe_lists (db/120) copied the old creator-only model — wrong for
-- company kitchens: a project the admin fills with recipes must be visible to the whole team.
--   · READ: everyone in the same kitchen sees the kitchen's projects and the recipes filed
--     into them. (Personal mode leaks nothing — a personal kitchen has exactly one member.)
--   · WRITE on the project itself (rename/hide/delete): stays creator-only.
--   · Filing recipes into a visible project: members insert their OWN is_personal recipes
--     carrying that list_id — db/97's insert policy already allows that.
--   · My Recipes (is_personal, list_id NULL) stay strictly private, and the additive
--     per-friend policy recipes_select_shared_to_me (db/143/144) is untouched.

drop policy if exists "own recipe lists" on recipe_lists;
create policy "read kitchen recipe lists" on recipe_lists
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    or created_by = auth.uid()
  );
create policy "insert own recipe lists" on recipe_lists
  for insert with check (created_by = auth.uid());
create policy "update own recipe lists" on recipe_lists
  for update using (created_by = auth.uid());
create policy "delete own recipe lists" on recipe_lists
  for delete using (created_by = auth.uid());

drop policy if exists "read kitchen recipes" on recipes;
create policy "read kitchen recipes" on recipes
  for select using (
    (kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and (not is_personal or list_id is not null))
    or created_by = auth.uid()
  );
