-- Sautero — Recipe comments + activity feed (Richard, 16.7., bod 2). Scoped to recipes only for
-- now (his own call, narrower than "everything shared") — Check List/Ingredients comments can
-- follow later using the same pattern if wanted. Notifications are in-app only (an activity
-- list you check when you open Sautero), not real push — also his own call.
--
-- Visibility is deliberately NOT duplicated from recipes' own RLS (kitchen-wide, or personal +
-- friend-shared via db/89/db/97) — a comment is readable/postable exactly when its recipe is,
-- via `recipe_id in (select id from recipes)`. Since `recipes` already has RLS, that subquery
-- is automatically filtered to whatever the CURRENT user can already see — correct by
-- construction, and never needs to be kept in sync with recipes' visibility rules by hand.

create table if not exists recipe_comments (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  created_by uuid not null references profiles(id),
  message text not null,
  created_at timestamptz not null default now()
);
create index if not exists recipe_comments_recipe_idx on recipe_comments(recipe_id, created_at);

alter table recipe_comments enable row level security;

create policy "read comments on visible recipes" on recipe_comments
  for select using (
    recipe_id in (select id from recipes)
  );
create policy "comment on visible recipes" on recipe_comments
  for insert with check (
    created_by = auth.uid() and recipe_id in (select id from recipes)
  );
create policy "delete own comments" on recipe_comments
  for delete using (created_by = auth.uid());

-- Activity feed: "unread" = comments on recipes YOU created, newer than the last time you
-- opened the activity list. One timestamp per person, not a per-comment read flag — simpler,
-- and matches how a notifications badge actually gets used (glance, open, cleared).
alter table profiles add column if not exists activity_last_seen_at timestamptz;
grant select (activity_last_seen_at) on profiles to authenticated;
