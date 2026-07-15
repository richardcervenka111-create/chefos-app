-- ChefOS -- "Coming soon" wall for uninvited strangers (Richard, 16.7.).
--
-- Scope, exact as confirmed: ONLY someone who reaches the page with zero invitation context --
-- no ?invite=/?join=/?friend= in the URL AND no existing session on this device -- sees a
-- holding message instead of the login form. Anyone with a real invite/QR/friend link, or who
-- has ever signed in on this browser before, is completely unaffected -- this is deliberately
-- NOT a full app kill-switch (Richard explicitly ruled that scope out).
--
-- A single-row config table, readable by `anon` (has to be -- this check runs BEFORE anyone
-- signs in) so Richard can flip it off directly in SQL with zero redeploy once the public trial
-- actually opens, e.g.:
--   update app_config set coming_soon_enabled = false where id = 1;
--
-- Fails OPEN in the app if this migration hasn't run yet or the query errors for any reason --
-- same rule as every other gate in app/index.html (hasAcceptedConfidentiality etc.): a missing
-- migration or a transient error must never lock anyone out, least of all the pilot kitchen.
--
-- Safe straight to production: new table, no data mutation, no changes to any existing table.

create table if not exists app_config (
  id int primary key default 1,
  coming_soon_enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  constraint app_config_singleton check (id = 1)
);

insert into app_config (id, coming_soon_enabled) values (1, true)
  on conflict (id) do nothing;

alter table app_config enable row level security;

-- Readable by anyone, signed in or not -- this is the one table that legitimately needs to work
-- before authentication exists. Nothing sensitive lives here, just one boolean.
create policy "anyone reads app config" on app_config
  for select using (true);

-- Only the super-admin can flip it -- matches the same single-super-admin-controls pattern used
-- for is_admin (db/80) and account_type-adjacent settings elsewhere.
create policy "super-admin updates app config" on app_config
  for update using (is_super_admin());
