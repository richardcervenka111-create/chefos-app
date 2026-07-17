-- 142: AI Usage for Kitchen Admins (Richard, 17.7.2026 bod 2): a kitchen's main admin
-- (admin_perms->company_admin) can read the ai_usage rows of their OWN kitchen only —
-- feeds the same Admin → AI Usage screen, scoped to their team. Head Admin keeps seeing
-- everything (db/139 policy); ordinary members still see only their own rows.

drop policy if exists ai_usage_select_kitchen_admin on ai_usage;
create policy ai_usage_select_kitchen_admin on ai_usage
  for select using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid()
        and p.kitchen_id = ai_usage.kitchen_id
        and coalesce((p.admin_perms->>'company_admin')::boolean, false)
    )
  );
