-- ChefOS — publishing guard (Richard, 17.7.): nobody working as a COMPANY profile may publish
-- company recipes — publishing is a Personal-profile right, for the person's own recipes.
--
-- The app already refuses in the UI (togglePublishRecipe shows a terms message on company
-- accounts). This trigger makes the rule real at the database: a recipe can only be flipped
-- to is_public=true when it is the caller's OWN, PERSONAL recipe. Company-created recipes have
-- is_personal=false, so they can never be published by anyone — which is exactly the rule.
-- Unpublishing (true -> false) is always allowed for whoever can update the row.

create or replace function guard_recipe_publish()
returns trigger as $$
begin
  if new.is_public and not coalesce(old.is_public, false) then
    if not new.is_personal or new.created_by is distinct from auth.uid() then
      raise exception 'Publishing is only allowed for your own personal recipes (ChefOS terms).';
    end if;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_guard_recipe_publish on recipes;
create trigger trg_guard_recipe_publish
  before update of is_public on recipes
  for each row execute function guard_recipe_publish();
