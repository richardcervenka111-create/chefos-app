-- Sautero — basic client-side error tracking (2026-07-13).
-- Backlog v2 (QA Lead): "keď sa niečo pokazí u cudzieho človeka na jeho telefóne, nedozvieš sa
-- to, kým ti sám nenapíše." This is the minimal version — no third-party service (Sentry etc.),
-- just a table + a window.onerror handler that logs to it (app/index.html).
create table if not exists error_logs (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid references kitchens(id),
  user_id uuid references auth.users(id),
  message text not null,
  stack text,
  url text,
  user_agent text,
  created_at timestamptz not null default now()
);
alter table error_logs enable row level security;

-- Anyone signed in can log an error against their own kitchen — this has to stay permissive
-- (not scoped tighter) since the whole point is capturing errors even when other app state is
-- broken/inconsistent.
create policy "log own errors" on error_logs
  for insert with check (auth.uid() is not null);

-- Only admins can read the log — this is diagnostic data about staff devices, not something
-- every team member needs visibility into.
create policy "admin read error logs" on error_logs
  for select using (
    exists (select 1 from profiles where id = auth.uid() and is_admin)
  );
