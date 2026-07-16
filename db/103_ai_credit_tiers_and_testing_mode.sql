-- ChefOS — AI credit follow-ups (Richard, 16.7.):
-- 1) First top-up keeps the 30% margin (70% credited); every top-up after that only takes 10%
--    margin (90% credited) — tracked with a simple "has this person ever topped up" flag rather
--    than trying to infer it from the current balance (which can legitimately hit zero again
--    for a returning person, that's not the same as "never topped up").
-- 2) A single platform-wide testing-mode switch: while ON, AI features are unlimited for
--    EVERYONE regardless of account type or credit balance (for the closed trial). While OFF,
--    normal credit gating applies exactly as before. Lives on app_config (db/96, same singleton
--    already used for the coming-soon wall) — Head Admin only, toggle from the app itself now
--    instead of raw SQL.

alter table profiles add column if not exists ai_credit_ever_topped_up boolean not null default false;
grant select (ai_credit_ever_topped_up) on profiles to authenticated;

alter table app_config add column if not exists ai_unlimited_testing_mode boolean not null default false;
