-- ChefOS — Working Time: one-time location snapshot at check-in/check-out (2026-07-14).
--
-- Richard asked for Working Time to know where the device was. Continuous movement tracking
-- would be legally sensitive (Swiss employee-GPS-tracking proportionality rules) and isn't
-- reliably possible for a locked-phone web app anyway (see chefos-founder feature-backlog notes
-- on "GPS-legal" being parked). Instead: capture the device's location ONCE, at the exact moment
-- of check-in and check-out only — enough to confirm "checked in from the actual kitchen", not a
-- movement history. If the browser denies/lacks geolocation, these columns just stay null; it
-- never blocks a check-in/out.

alter table time_entries add column if not exists check_in_lat double precision;
alter table time_entries add column if not exists check_in_lng double precision;
alter table time_entries add column if not exists check_out_lat double precision;
alter table time_entries add column if not exists check_out_lng double precision;

-- No RLS changes needed: time_entries already only allows a user to read/write their own rows
-- (db/39_working_time.sql) — nobody else, including teammates or admins, can see these values.
