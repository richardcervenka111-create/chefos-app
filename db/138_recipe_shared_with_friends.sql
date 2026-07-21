-- Sautero — per-recipe friend sharing (Richard, 17.7.: "share with friends" on a recipe only
-- ever showed PUBLIC recipes to friends, not the ones shared just with friends). Ingredients
-- already work per-item (db/136); this brings recipes to the same model: a recipe can be shared
-- with friends individually, and a connected friend sees exactly those (plus public ones).
--
-- The old global profiles.recipes_shared toggle (db/89) stays and still works (share ALL) — this
-- adds a second, per-recipe path OR'd on top of it.

alter table recipes add column if not exists shared_with_friends boolean not null default false;
grant select (shared_with_friends) on recipes to authenticated;
grant update (shared_with_friends) on recipes to authenticated;
create index if not exists recipes_shared_friends_idx on recipes(shared_with_friends) where shared_with_friends;

drop policy if exists "read connected shared recipes per item" on recipes;
create policy "read connected shared recipes per item" on recipes
  for select using (
    shared_with_friends
    and created_by is not null
    and created_by <> auth.uid()
    and exists (
      select 1 from chef_connections c
      where (c.user_a = auth.uid() and c.user_b = recipes.created_by)
         or (c.user_b = auth.uid() and c.user_a = recipes.created_by)
    )
  );

-- Guard: turning is_public OR shared_with_friends ON is allowed only for your OWN, personal
-- recipe, and only from a PERSONAL profile (point 5 — company profiles share nothing). Replaces
-- db/133's is_public-only guard; unpublishing/unsharing is always allowed.
create or replace function guard_recipe_publish()
returns trigger as $$
begin
  if (new.is_public and not coalesce(old.is_public, false))
     or (new.shared_with_friends and not coalesce(old.shared_with_friends, false)) then
    if not new.is_personal
       or new.created_by is distinct from auth.uid()
       or coalesce((select account_type from profiles where id = auth.uid()), '') <> 'personal' then
      raise exception 'Publishing/sharing is only allowed for your own personal recipes, from a Personal profile (Sautero terms).';
    end if;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_guard_recipe_publish on recipes;
create trigger trg_guard_recipe_publish
  before update of is_public, shared_with_friends on recipes
  for each row execute function guard_recipe_publish();
