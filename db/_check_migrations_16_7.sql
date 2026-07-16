-- ChefOS — read-only kontrola (Richard, 16.7.): overí, že všetko z dnešných migrácií
-- (db/97 – db/110) v databáze naozaj existuje. NIČ NEMENÍ — len číta a vypíše tabuľku
-- s ✅/❌ pre každý kus. Ak je všetko ✅, dnešný balík je kompletný.
-- (Podčiarkovník v názve súboru = nie je to migrácia, len pomocná kontrola.)

with checks(what, ok) as (
  values
  -- db/97 — súkromie osobných dát + tímy
  ('db/97: recipes.is_personal',            exists(select 1 from information_schema.columns where table_name='recipes' and column_name='is_personal')),
  ('db/97: ingredients.is_personal',        exists(select 1 from information_schema.columns where table_name='ingredients' and column_name='is_personal')),
  ('db/97: kitchens.join_code_hash',        exists(select 1 from information_schema.columns where table_name='kitchens' and column_name='join_code_hash')),
  ('db/97: profiles.skip_account_type_confirm', exists(select 1 from information_schema.columns where table_name='profiles' and column_name='skip_account_type_confirm')),
  ('db/97: profiles.team_join_seen',        exists(select 1 from information_schema.columns where table_name='profiles' and column_name='team_join_seen')),
  ('db/97: funkcia create_team',            exists(select 1 from pg_proc where proname='create_team')),
  ('db/97: funkcia join_team_by_code',      exists(select 1 from pg_proc where proname='join_team_by_code')),
  ('db/97: funkcia lookup_team_by_code',    exists(select 1 from pg_proc where proname='lookup_team_by_code')),
  ('db/97: funkcia regenerate_join_code',   exists(select 1 from pg_proc where proname='regenerate_join_code')),
  -- db/98 — feedback tabuľka (dnes už nepoužívaná, ale mala existovať)
  ('db/98: tabuľka feedback',               exists(select 1 from information_schema.tables where table_name='feedback')),
  -- db/99 — kitchen reports + súhlas zamestnanca
  ('db/99: profiles.performance_tracking_consent', exists(select 1 from information_schema.columns where table_name='profiles' and column_name='performance_tracking_consent')),
  ('db/99: admin-read politika na time_entries', exists(select 1 from pg_policies where tablename='time_entries' and policyname='kitchen admins read consented time entries')),
  -- db/100 — privacy consent
  ('db/100: tabuľka privacy_acceptances',   exists(select 1 from information_schema.tables where table_name='privacy_acceptances')),
  -- db/101 — zavretá stará diera na tvorbu kuchýň
  ('db/101: stará "create kitchen" politika PREČ', not exists(select 1 from pg_policies where tablename='kitchens' and policyname='create kitchen')),
  -- db/102 + db/103 — AI kredit + testing mode
  ('db/102: profiles.ai_credit_chf',        exists(select 1 from information_schema.columns where table_name='profiles' and column_name='ai_credit_chf')),
  ('db/103: profiles.ai_credit_ever_topped_up', exists(select 1 from information_schema.columns where table_name='profiles' and column_name='ai_credit_ever_topped_up')),
  ('db/103: app_config.ai_unlimited_testing_mode', exists(select 1 from information_schema.columns where table_name='app_config' and column_name='ai_unlimited_testing_mode')),
  -- db/104 — komentáre + aktivita
  ('db/104: tabuľka recipe_comments',       exists(select 1 from information_schema.tables where table_name='recipe_comments')),
  ('db/104: profiles.activity_last_seen_at', exists(select 1 from information_schema.columns where table_name='profiles' and column_name='activity_last_seen_at')),
  -- db/105 — zdieľané ingrediencie len admin
  ('db/105: funkcia _has_any_admin_role',   exists(select 1 from pg_proc where proname='_has_any_admin_role')),
  -- db/106 — email_contacts trigger + backfill
  ('db/106: trigger na access_requests',    exists(select 1 from pg_trigger where tgname='on_access_request_sync_email_contact')),
  ('db/106: patriklachky v email_contacts', exists(select 1 from email_contacts where email='patriklachky@gmail.com')),
  -- db/107 — skrývanie ingrediencií
  ('db/107: ingredients.hidden',            exists(select 1 from information_schema.columns where table_name='ingredients' and column_name='hidden')),
  -- db/108 — feedback inbox pre teba
  ('db/108: read politika na feedback_reports', exists(select 1 from pg_policies where tablename='feedback_reports' and policyname='head admin reads all feedback reports')),
  -- db/109 — Add Company + asistenti
  ('db/109: kitchen_invites.grants_company_admin', exists(select 1 from information_schema.columns where table_name='kitchen_invites' and column_name='grants_company_admin')),
  ('db/109: funkcia create_company',        exists(select 1 from pg_proc where proname='create_company')),
  ('db/109: funkcia claim_company_admin',   exists(select 1 from pg_proc where proname='claim_company_admin')),
  ('db/109: funkcia set_member_assistant',  exists(select 1 from pg_proc where proname='set_member_assistant')),
  -- db/110 — vlastná kuchyňa pre nových
  ('db/110: funkcia ensure_personal_kitchen', exists(select 1 from pg_proc where proname='ensure_personal_kitchen'))
)
select
  what as "Čo",
  case when ok then '✅ OK' else '❌ CHÝBA' end as "Stav"
from checks
order by ok, what;
