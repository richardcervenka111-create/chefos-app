-- ChefOS — My Profile: optional extra fields (2026-07-15).
--
-- Richard wants My Profile to hold more info about people, with these as optional (not part of
-- the mandatory first-login gate, which stays just name/age/gender to keep onboarding fast).
-- Editable anytime from the 👤 My Profile screen. `role` already existed (db/01_schema.sql) but
-- was never editable from the app until now.

alter table profiles add column if not exists phone text;
alter table profiles add column if not exists bio text;
