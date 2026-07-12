-- TEST/PREVIEW DATA ONLY — NOT a schema migration, safe to skip entirely.
--
-- Richard asked to see what "Hours by Month" (the new pie-chart view) actually looks like with
-- data in it. This inserts ~5 months of randomized past time_entries rows for his own account
-- only (matched by email) — random check-in/out times, some days pushing past 8h so the
-- overtime slice actually shows up in the pie. About 70% of days in range get an entry, so
-- months don't look unrealistically full.
--
-- Safe to delete afterwards with:
--   delete from time_entries
--   where user_id = (select id from auth.users where email = 'richard.cervenka111@gmail.com')
--     and created_at > now() - interval '10 minutes';
-- (run that right after this script, while the "created_at > now() - 10 minutes" window still
-- covers everything it just inserted).

insert into time_entries (kitchen_id, user_id, check_in, check_out, break_minutes)
select kitchen_id, user_id, check_in, check_in + (hours_worked || ' hours')::interval, break_minutes
from (
  select
    p.kitchen_id,
    u.id as user_id,
    d + interval '10 hours' + (random() * interval '2 hours') as check_in,
    6 + random() * 5 as hours_worked,
    (floor(random() * 3) * 15)::int as break_minutes
  from auth.users u
  join profiles p on p.id = u.id
  cross join generate_series(
    date_trunc('month', now()) - interval '5 months',
    date_trunc('month', now()) - interval '1 day',
    interval '1 day'
  ) as d
  where u.email = 'richard.cervenka111@gmail.com'
    and random() < 0.7
) x;
