-- Sautero — Kitchen Reports (Richard, 16.7., bod 2): the same 📊 icon Head Admin has for
-- Internal Docs, but for a Kitchen Admin at their own restaurant — an infographic of THEIR
-- kitchen's own data (recipe count, Check List activity, team size) plus per-employee hours,
-- gated behind that employee's own explicit consent (Richard's answer to the follow-up
-- question about named performance data: consent-gated, not aggregate-only).
--
-- What "performance" actually means here: hours logged via Working Time (time_entries, db/39)
-- — real, already-collected data. NOT a manufactured "tasks completed" score: neither `tasks`
-- nor `prep_items` track who completed something or when, only who created it (see HEALTH_LOG/
-- project memory) — no report here claims otherwise.

-- New admin_perms key (db/85 jsonb column, no schema change) — a Kitchen Admin needs this
-- specifically to see reports, same one-perm-per-feature convention as every other admin_perms
-- key (view_email_contacts, approve_access, ...).
-- (ADMIN_PERM_DEFS entry added client-side in app/index.html.)

alter table profiles add column if not exists performance_tracking_consent boolean not null default false;
alter table profiles add column if not exists performance_tracking_consent_at timestamptz;
grant select (performance_tracking_consent) on profiles to authenticated;

-- time_entries (db/39) currently has NO admin-read policy at all — only "read own time
-- entries". This adds exactly one narrow path: a kitchen admin with view_kitchen_reports (or
-- Head Admin) can read time_entries for people who worked the consent checkbox ON, in their own
-- kitchen only. Someone who never consents is invisible here, permanently, by design.
create policy "kitchen admins read consented time entries" on time_entries
  for select using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.kitchen_id = time_entries.kitchen_id
        and (p.is_admin or (p.admin_perms->>'view_kitchen_reports')::boolean is true)
    )
    and exists (
      select 1 from profiles emp
      where emp.id = time_entries.user_id and emp.performance_tracking_consent is true
    )
  );
