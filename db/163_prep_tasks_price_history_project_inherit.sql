-- Sautero — Check List dishes/tasks + ingredient price history: inherit personal/company
-- privacy from their parent (2026-07-19, found during the broader kitchen_id audit that
-- followed the ingredient_lists/recipe_lists fix in db/162).
--
-- projects.is_personal (db/159) correctly hides a personal PROJECT from teammates. But the
-- DISHES and TASKS *inside* that project were never updated to check it — their SELECT
-- policy only checked "project_id IN (select id from projects)" with no is_personal filter,
-- so any kitchen member could read (and, worse, UPDATE/DELETE — those policies had no
-- project_id/is_personal check at all, just kitchen_id) another member's personal-project
-- prep dishes and tasks. prep_items already inherits correctly once prep_dishes is fixed,
-- since its own policy filters through "dish_id IN (select id from prep_dishes)", which is
-- itself RLS-filtered for the querying role.
--
-- ingredient_price_history has the same shape: kitchen_id-only, no check that the ingredient
-- it logs a price for is itself company-visible (ingredients.is_personal, db/162).
--
-- No new columns needed — both dishes/tasks and price history already carry a foreign key
-- (project_id / ingredient_id) to a parent that already has is_personal.

drop policy if exists "read kitchen prep dishes" on prep_dishes;
create policy "read kitchen prep dishes" on prep_dishes for select using (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  and (project_id is null or project_id in (
    select id from projects where not is_personal or created_by = auth.uid()
  ))
);

drop policy if exists "update kitchen prep dishes" on prep_dishes;
create policy "update kitchen prep dishes" on prep_dishes for update using (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  and (project_id is null or project_id in (
    select id from projects where not is_personal or created_by = auth.uid()
  ))
);

drop policy if exists "delete kitchen prep dishes" on prep_dishes;
create policy "delete kitchen prep dishes" on prep_dishes for delete using (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  and (project_id is null or project_id in (
    select id from projects where not is_personal or created_by = auth.uid()
  ))
);

drop policy if exists "write kitchen prep dishes" on prep_dishes;
create policy "write kitchen prep dishes" on prep_dishes for insert with check (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  and (project_id is null or project_id in (
    select id from projects where not is_personal or created_by = auth.uid()
  ))
);

drop policy if exists "read kitchen tasks" on tasks;
create policy "read kitchen tasks" on tasks for select using (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  and (project_id is null or project_id in (
    select id from projects where not is_personal or created_by = auth.uid()
  ))
);

drop policy if exists "update kitchen tasks" on tasks;
create policy "update kitchen tasks" on tasks for update using (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  and (project_id is null or project_id in (
    select id from projects where not is_personal or created_by = auth.uid()
  ))
);

drop policy if exists "delete kitchen tasks" on tasks;
create policy "delete kitchen tasks" on tasks for delete using (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  and (project_id is null or project_id in (
    select id from projects where not is_personal or created_by = auth.uid()
  ))
);

drop policy if exists "write kitchen tasks" on tasks;
create policy "write kitchen tasks" on tasks for insert with check (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  and (project_id is null or project_id in (
    select id from projects where not is_personal or created_by = auth.uid()
  ))
);

drop policy if exists "read kitchen price history" on ingredient_price_history;
create policy "read kitchen price history" on ingredient_price_history for select using (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  and ingredient_id in (
    select id from ingredients where not is_personal or created_by = auth.uid()
  )
);

drop policy if exists "write kitchen price history" on ingredient_price_history;
create policy "write kitchen price history" on ingredient_price_history for insert with check (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  and ingredient_id in (
    select id from ingredients where not is_personal or created_by = auth.uid()
  )
);
