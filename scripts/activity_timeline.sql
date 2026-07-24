-- Sautero — "what was I doing at HH:MM?" (Richard, 24.7.2026)
--
-- Richard asked to be able to say: "at such and such a time I was doing this, and I need it like
-- that" — and have the answer come from data rather than memory. usage_events already held the
-- raw material (login + which screen was opened), but nothing about what he actually DID; as of
-- 24.7. the app also records recipe_saved, item_deleted, prep_dish_purged, prep_item_purged,
-- scan_prep_sheet and mode_switched. Everything is Europe/Zurich here — never UTC.
--
-- HOW TO USE: paste into the Supabase SQL editor and edit the two timestamps (and the email if
-- you want a different account). Nothing here writes; it is safe to run any time.

-- ============================================================ 1. Timeline for one window
select
  to_char(e.created_at at time zone 'Europe/Zurich', 'DD.MM HH24:MI:SS') as cas,
  e.name                                                                 as udalost,
  coalesce(e.meta->>'view', e.meta->>'title', e.meta->>'name', e.meta->>'to', '') as detail,
  k.name                                                                 as kuchyna
from usage_events e
join profiles p on p.id = e.user_id
left join kitchens k on k.id = e.kitchen_id
where lower(p.email) = 'richard.cervenka@icloud.com'
  and (e.created_at at time zone 'Europe/Zurich')
      between timestamp '2026-07-23 15:00' and timestamp '2026-07-23 18:00'
order by e.created_at;

-- ============================================================ 2. A whole day, condensed
-- Consecutive identical events collapse into one line with a count, so a day reads as a story
-- instead of 1'000 rows of view_opened.
with ev as (
  select e.created_at, e.name,
         coalesce(e.meta->>'view', e.meta->>'title', e.meta->>'name', '') as detail
  from usage_events e join profiles p on p.id = e.user_id
  where lower(p.email) = 'richard.cervenka@icloud.com'
    and (e.created_at at time zone 'Europe/Zurich')::date = date '2026-07-23'
), grp as (
  select *, row_number() over (order by created_at)
          - row_number() over (partition by name, detail order by created_at) as g
  from ev
)
select to_char(min(created_at) at time zone 'Europe/Zurich','HH24:MI') as od,
       to_char(max(created_at) at time zone 'Europe/Zurich','HH24:MI') as do,
       name, detail, count(*) as kolkokrat
from grp group by g, name, detail
order by min(created_at);

-- ============================================================ 3. Only the things that CHANGED data
-- The short answer to "what did I actually do that day" — navigation stripped out.
select to_char(e.created_at at time zone 'Europe/Zurich','DD.MM HH24:MI') as cas,
       e.name, e.meta
from usage_events e join profiles p on p.id = e.user_id
where lower(p.email) = 'richard.cervenka@icloud.com'
  and e.name not in ('view_opened', 'login', 'recipe_source_filter_changed')
  and e.created_at >= now() - interval '7 days'
order by e.created_at desc;

-- ============================================================ 4. Cross-check against the database
-- usage_events records intent; these are the rows that actually exist. Useful when the two
-- disagree — e.g. a save that logged but never landed.
select 'recipes'  as tabulka, to_char(r.created_at at time zone 'Europe/Zurich','DD.MM HH24:MI') as cas, r.title as co
  from recipes r join profiles p on p.id = r.created_by
  where lower(p.email) = 'richard.cervenka@icloud.com' and r.created_at >= now() - interval '7 days'
union all
select 'prep_dishes', to_char(d.created_at at time zone 'Europe/Zurich','DD.MM HH24:MI'), d.name
  from prep_dishes d where d.created_at >= now() - interval '7 days'
order by cas;
