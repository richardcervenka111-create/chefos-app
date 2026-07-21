-- db/168: a Company Admin sees the hours in their own Company Report too.
--
-- Making the Company Report visible to every company_admin (Richard, 21.7.) showed the tile, but
-- the underlying time_entries read policy (db/99) only allowed is_admin or view_kitchen_reports —
-- so a company_admin's report came back with no hours. Add company_admin to that admin check.
-- Unchanged safety: still their OWN kitchen only, and still only for employees who turned the
-- performance-tracking consent ON.
drop policy if exists "kitchen admins read consented time entries" on time_entries;
create policy "kitchen admins read consented time entries" on time_entries
  for select using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.kitchen_id = time_entries.kitchen_id
        and (p.is_admin
             or (p.admin_perms->>'view_kitchen_reports')::boolean is true
             or (p.admin_perms->>'company_admin')::boolean is true)
    )
    and exists (
      select 1 from profiles emp
      where emp.id = time_entries.user_id and emp.performance_tracking_consent is true
    )
  );
