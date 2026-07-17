-- 143: per-friend recipe sharing + notification (Richard, 17.7.2026 bod 1: "share my recipe
-- bude mať samostatnú dlaždicu kde si môžem zvoliť s ktorým friend chcem zdieľať recipe
-- poprípade ho na to aj upozorniť").
--
-- Until now recipes.shared_with_friends was all-or-nothing (every connected friend sees it).
-- recipe_shares targets ONE friend at a time: the owner picks the friend(s) per recipe, and
-- `seen` powers a one-time "X shared a recipe with you" notice on the friend's next open.
--
-- Rules baked into RLS (mirror of guard_recipe_publish, db/138): only the recipe's OWNER can
-- share, only their own is_personal recipes, only from a personal-account profile (company
-- profiles share NOTHING), and only to people who are actually their chef_connections friends.
-- The friend gets read access to the shared recipe itself via the extra recipes SELECT policy
-- below — Postgres ORs SELECT policies, so this only ever widens visibility for exactly the
-- shared rows.
--
-- KNOWN LIMIT (same class as the db/119→132 lesson): recipe_comments' INSERT policy enumerates
-- visibility classes and does NOT include per-friend shares — a friend can VIEW a recipe shared
-- this way but not comment on it. Deliberate for now; extend recipe_comments when commenting on
-- per-friend shares becomes a requirement.

create table if not exists recipe_shares (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  friend_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  seen boolean not null default false,
  unique (recipe_id, friend_id)
);

alter table recipe_shares enable row level security;

drop policy if exists rs_owner_manage on recipe_shares;
create policy rs_owner_manage on recipe_shares
  for all using (owner_id = auth.uid())
  with check (
    owner_id = auth.uid()
    and exists (select 1 from recipes r where r.id = recipe_id and r.created_by = auth.uid() and r.is_personal)
    and exists (select 1 from profiles p where p.id = auth.uid() and p.account_type = 'personal')
    and exists (select 1 from chef_connections c
                where (c.user_a = auth.uid() and c.user_b = friend_id)
                   or (c.user_b = auth.uid() and c.user_a = friend_id))
  );

drop policy if exists rs_friend_select on recipe_shares;
create policy rs_friend_select on recipe_shares
  for select using (friend_id = auth.uid());

drop policy if exists rs_friend_mark_seen on recipe_shares;
create policy rs_friend_mark_seen on recipe_shares
  for update using (friend_id = auth.uid()) with check (friend_id = auth.uid());

drop policy if exists recipes_select_shared_to_me on recipes;
create policy recipes_select_shared_to_me on recipes
  for select using (
    exists (select 1 from recipe_shares rs where rs.recipe_id = recipes.id and rs.friend_id = auth.uid())
  );

create index if not exists recipe_shares_friend_idx on recipe_shares (friend_id, seen);
create index if not exists recipe_shares_owner_idx on recipe_shares (owner_id, recipe_id);
