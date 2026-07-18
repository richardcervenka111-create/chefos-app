-- 152: cleanup follow-up to db/148 — Postgres does NOT let CREATE OR REPLACE swap in a new
-- argument list; adding p_email to create_company() created a SECOND overload instead of
-- replacing the original, confirmed live in prod right after running db/148 (pg_proc showed
-- both create_company(p_name text) and create_company(p_name text, p_email text) side by
-- side). The app only ever calls the 2-arg form now (submitAddCompany passes p_email), so the
-- 1-arg original is dead and, being ambiguous with the 2-arg version's default, is worth
-- dropping rather than leaving two overloads of the same name around.
--
-- Safe straight to production — drops an unused function overload, not a table; nothing else
-- in app/index.html calls the 1-arg form.

drop function if exists create_company(text);
