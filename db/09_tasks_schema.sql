-- ChefOS — Mise en Place / prep task list
-- A task can optionally point at a recipe (to borrow its title/production time) or stand
-- entirely on its own. Priority 1 = critical, 5 = low. Kitchen-scoped (same pattern as
-- recipes/ingredients) so this is ready for a shared team board later without a schema
-- change — for now the app only shows "my" view of it, per Richard's 2026-07-09 call.
create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),

  station text,
  task text not null,
  priority smallint not null default 3 check (priority between 1 and 5),

  recipe_id uuid references recipes(id) on delete set null,
  production_time text,

  done boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table tasks enable row level security;

create policy "read kitchen tasks" on tasks
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "write kitchen tasks" on tasks
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "update kitchen tasks" on tasks
  for update using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "delete kitchen tasks" on tasks
  for delete using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
