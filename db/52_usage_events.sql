-- ChefOS — minimal usage analytics (2026-07-13).
-- Backlog v2 (PM + CTO): "bez telemetrie nevieš, či 25 ľudí appku reálne používa alebo len raz
-- otvorilo." No third-party analytics — a plain events table, logged from app/index.html at
-- login and whenever a top-level module (Recipes, Check List, Ingredients, ...) is opened.
create table if not exists usage_events (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid references kitchens(id),
  user_id uuid references auth.users(id),
  name text not null,
  meta jsonb,
  created_at timestamptz not null default now()
);
alter table usage_events enable row level security;

create policy "log own usage events" on usage_events
  for insert with check (auth.uid() is not null);

-- Only admins can read it back — this is usage/behavior data about the team, not something
-- every member needs to see about each other.
create policy "admin read usage events" on usage_events
  for select using (
    exists (select 1 from profiles where id = auth.uid() and is_admin)
  );
