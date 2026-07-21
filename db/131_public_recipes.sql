-- Sautero — Public recipes shelf (Richard, 17.7.): any chef can PUBLISH their own recipe, and
-- it appears on a new "Public" shelf visible to every account across every kitchen — the same
-- reach as the Sautero library, but community-built. Unlike Sautero recipes (which are COPIED
-- into each kitchen), a public recipe stays ONE row owned by its author; everyone else reads
-- that same row via the new select policy below.

alter table recipes add column if not exists is_public boolean not null default false;
alter table recipes add column if not exists published_at timestamptz;
grant select (is_public, published_at) on recipes to authenticated;
grant update (is_public, published_at) on recipes to authenticated;
create index if not exists recipes_public_idx on recipes(is_public) where is_public;

-- Everyone (authenticated) can read published recipes — ORs with the existing kitchen/own
-- policies. Publishing/unpublishing itself goes through the existing "update kitchen recipes"
-- policy, so only people who could already edit the recipe can flip the switch (the app UI
-- additionally limits the button to the recipe's own author).
drop policy if exists "read public recipes" on recipes;
create policy "read public recipes" on recipes
  for select using (is_public);

-- Comments: INSERT already works automatically (db/104's policy checks `recipe_id in (select
-- id from recipes)`, which is RLS-filtered per reader — public rows are now in it). READ needs
-- its own branch, because db/129's read policy enumerates visibility explicitly.
drop policy if exists "read comments on public recipes" on recipe_comments;
create policy "read comments on public recipes" on recipe_comments
  for select using (
    exists (select 1 from recipes p where p.id = recipe_comments.recipe_id and p.is_public)
  );
