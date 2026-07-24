-- Sautero — ingredient info coverage watchdog (Richard, 24.7.2026:
-- "AI doplnanie informácií o surovinách treba tiež dať kontrolovať a automaticky aktualizovať
--  a chybajúce doplnať")
--
-- On 24.7. the backfill reached 100%: every one of the 2'072 distinct ingredient names had a
-- flavour, an origin and a season. That is a snapshot, not a guarantee — every recipe scan and
-- every hand-typed ingredient can add a new name with all three fields empty, and nothing
-- currently notices. These queries are the watchdog: run 1 and 2 regularly, and if the gap is
-- non-zero, fill it the same way db/171–183 did (only-empty updates, matched on lower(trim(name))).
--
-- NOT wired into CI yet, and that is deliberate rather than forgotten: the health-check workflows
-- have no database credentials (SAUTERO_DB_URL is still one of the secrets Richard has to add —
-- see the QA automation note). Until then this is the manual check, and it takes ten seconds.

-- ============================================================ 1. The headline number
select
  count(*)                                                              as vsetky_nazvy,
  count(*) filter (where coalesce(flavour,'') = '')                     as bez_chuti,
  count(*) filter (where coalesce(origin,'')  = '')                     as bez_povodu,
  count(*) filter (where coalesce(season,'')  = '')                     as bez_sezony,
  count(*) filter (where coalesce(flavour,'') = '' or coalesce(origin,'') = ''
                      or coalesce(season,'')  = '')                     as chyba_aspon_jedno,
  round(100.0 * count(*) filter (where coalesce(flavour,'') <> '' and coalesce(origin,'') <> ''
                                   and coalesce(season,'')  <> '') / nullif(count(*),0), 1)
                                                                        as pokrytie_pct
from (
  select distinct on (lower(trim(name))) name, flavour, origin, season
  from ingredients order by lower(trim(name))
) t;

-- ============================================================ 2. Exactly which names are missing
-- Feed this list straight into the next backfill batch. Newest first, because a fresh gap almost
-- always comes from a scan someone just ran.
select lower(trim(i.name)) as nazov,
       count(*)            as kolko_kuchyn,
       max(i.created_at)   as naposledy_pridane,
       case when coalesce(max(i.flavour),'') = '' then 'chut ' else '' end ||
       case when coalesce(max(i.origin),'')  = '' then 'povod ' else '' end ||
       case when coalesce(max(i.season),'')  = '' then 'sezona' else '' end as chyba
from ingredients i
group by lower(trim(i.name))
having coalesce(max(i.flavour),'') = '' or coalesce(max(i.origin),'') = '' or coalesce(max(i.season),'') = ''
order by max(i.created_at) desc;

-- ============================================================ 3. Suspicious values worth a look
-- Placeholder-ish text that satisfies "not empty" without actually saying anything, plus the
-- HTML-escaping glitch class we hit on 24.7. ("Salads &amp; Starters" stored literally).
select lower(trim(name)) as nazov, flavour, origin, season
from ingredients
where flavour ilike '%&amp;%' or origin ilike '%&amp;%' or season ilike '%&amp;%'
   or lower(trim(coalesce(flavour,''))) in ('n/a','na','unknown','-','?','tbd')
   or lower(trim(coalesce(origin,'')))  in ('n/a','na','unknown','-','?','tbd')
   or lower(trim(coalesce(season,'')))  in ('n/a','na','unknown','-','?','tbd')
group by 1,2,3,4
order by 1;

-- ============================================================ 4. New names since a given date
-- "What did the scans add this week that nobody has described yet?"
select lower(trim(name)) as nazov, min(created_at) as prve_pridanie
from ingredients
where created_at >= now() - interval '7 days'
group by 1
having coalesce(max(flavour),'') = '' or coalesce(max(origin),'') = '' or coalesce(max(season),'') = ''
order by 2 desc;
