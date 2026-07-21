-- Sautero — ingredient sharing (Richard, 17.7. bod 5+6): a personal-profile chef can share their
-- own My-Ingredients rows PUBLICLY (a cross-kitchen Public shelf, mirroring recipes db/131) or
-- with their chef FRIENDS (per-ingredient, mirroring the recipe friend model db/89). Company
-- profiles can share NOTHING (point 5) — enforced app-side AND by the guard trigger below.

alter table ingredients add column if not exists is_public boolean not null default false;
alter table ingredients add column if not exists published_at timestamptz;
alter table ingredients add column if not exists shared_with_friends boolean not null default false;
grant select (is_public, published_at, shared_with_friends) on ingredients to authenticated;
grant update (is_public, published_at, shared_with_friends) on ingredients to authenticated;
create index if not exists ingredients_public_idx on ingredients(is_public) where is_public;
create index if not exists ingredients_shared_idx on ingredients(shared_with_friends) where shared_with_friends;

-- READ: additive OR-branches on top of the existing kitchen/personal policies (db/97 etc.).
-- Public — anyone authenticated.
drop policy if exists "read public ingredients" on ingredients;
create policy "read public ingredients" on ingredients
  for select using (is_public);

-- Friend-shared — only a real chef_connections friend of the owner, and only rows the owner
-- flagged, and never your own (that path is already covered). Mirrors db/89 for recipes.
drop policy if exists "read connected shared ingredients" on ingredients;
create policy "read connected shared ingredients" on ingredients
  for select using (
    shared_with_friends
    and created_by is not null
    and created_by <> auth.uid()
    and exists (
      select 1 from chef_connections c
      where (c.user_a = auth.uid() and c.user_b = ingredients.created_by)
         or (c.user_b = auth.uid() and c.user_a = ingredients.created_by)
    )
  );

-- GUARD: turning is_public / shared_with_friends ON is allowed only for your OWN, personal
-- (My-Ingredients) row, and only while you're on a PERSONAL profile. That is exactly point 5:
-- company profiles can share nothing, and the same person can share once back on Personal.
-- Turning sharing OFF (taking something down) is always allowed for whoever can update the row.
create or replace function guard_ingredient_share()
returns trigger as $$
begin
  if (new.is_public and not coalesce(old.is_public, false))
     or (new.shared_with_friends and not coalesce(old.shared_with_friends, false)) then
    if not new.is_personal
       or new.created_by is distinct from auth.uid()
       or coalesce((select account_type from profiles where id = auth.uid()), '') <> 'personal' then
      raise exception 'Only your own personal ingredients can be shared, and only from a Personal profile (Sautero terms).';
    end if;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_guard_ingredient_share on ingredients;
create trigger trg_guard_ingredient_share
  before update of is_public, shared_with_friends on ingredients
  for each row execute function guard_ingredient_share();
