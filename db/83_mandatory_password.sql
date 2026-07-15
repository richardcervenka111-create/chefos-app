-- ChefOS -- Mandatory password (Richard, 15.7. late night, bod 7).
--
-- Safe straight to production: pure additive column, no data mutation, defaults everyone to
-- "not set yet" so the new gate in app/index.html (hasSetPassword/savePasswordGate, shown
-- right after the confidentiality gate) catches every existing account on their next login.
-- The emailed one-time code keeps working for everyone regardless -- this is a mandatory
-- SECOND way in, not a replacement for the first.

alter table profiles add column if not exists password_set boolean not null default false;
