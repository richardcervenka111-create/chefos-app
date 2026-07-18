-- 159: Check List projects — personal vs company split + admin-only company creation
-- (Richard, 19.7., live privacy report: a project created on his icloud account in PERSONAL
-- mode was visible to the protonmail and gmail accounts, in both modes. His spec, verbatim:
--   1. anything created in personal mode is visible ONLY to its creator, for every user;
--   2. in company mode a plain member may create sections inside existing projects, but
--      PROJECTS themselves are created only by the team's kitchen admin.)
--
-- Same class and same shape as db/156 (order_list_items): projects gains is_personal set by
-- the app from the account mode at write time; RLS makes personal projects creator-only at
-- the database level (not just hidden by the UI). Company-project INSERT becomes admin-only
-- (Head Admin / company_admin) — the app hides the Add Project tile for members in company
-- mode, the policy enforces it.
--
-- DEPTH: prep_dishes / tasks / prep_items read policies now inherit project visibility via a
-- subquery on projects — RLS inside the subquery runs as the caller, so a personal project's
-- dishes/items/tasks are invisible to teammates even through the raw API. project_id IS NULL
-- rows (pre-project era, db/94 backfilled them, but belt-and-braces) stay kitchen-visible.
--
-- Existing rows: default false = company, exactly today's behaviour — no guessing about
-- which old projects were "meant" personal. Richard's icloud test project stays visible as a
-- company project; he can delete it or recreate it in personal mode.
--
-- STAGING FIRST (RLS policy changes on live tables; run scripts/tenant_isolation_test.sql on
-- staging after applying).

alter table projects add column if not exists is_personal boolean not null default false;
grant select (is_personal) on projects to authenticated;

drop policy if exists "read kitchen projects" on projects;
create policy "read kitchen projects" on projects
  for select using (
    (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
    or (is_personal and created_by = auth.uid())
  );

drop policy if exists "create kitchen projects" on projects;
create policy "create kitchen projects" on projects
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    and (
      (is_personal and created_by = auth.uid())
      or (not is_personal and exists (
        select 1 from profiles
        where id = auth.uid() and (is_admin or (admin_perms->>'company_admin')::boolean is true)
      ))
    )
  );

drop policy if exists "update kitchen projects" on projects;
create policy "update kitchen projects" on projects
  for update using (
    (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
    or (is_personal and created_by = auth.uid())
  );

-- Content inherits project visibility (subqueries run under the caller's own projects RLS).
drop policy if exists "read kitchen prep dishes" on prep_dishes;
create policy "read kitchen prep dishes" on prep_dishes
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    and (project_id is null or project_id in (select id from projects))
  );

drop policy if exists "read kitchen tasks" on tasks;
create policy "read kitchen tasks" on tasks
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    and (project_id is null or project_id in (select id from projects))
  );

drop policy if exists "read kitchen prep items" on prep_items;
create policy "read kitchen prep items" on prep_items
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    and dish_id in (select id from prep_dishes)
  );
