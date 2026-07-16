-- ChefOS — AI credit balance for Personal accounts (Richard, 16.7., follow-up to db/97/bod 8).
--
-- Replaces the plain is_subscribed ON/OFF flag with a real CHF balance: Richard records what
-- he actually received (still manual/invoiced — no live payment gateway exists, matching the
-- monetization plan), the app credits 70% of that amount (ChefOS keeps a ~30% margin), and every
-- real AI call deducts its actual Anthropic cost from the balance server-side (claude-proxy).
-- When the balance hits zero, AI features stop working for that Personal account until Richard
-- (or the person, once real self-serve billing exists) tops it up again.
--
-- is_subscribed (db/97) is left in place, unused from now on — safe, harmless dead column,
-- not worth a destructive drop for a same-day change.

alter table profiles add column if not exists ai_credit_chf numeric not null default 0;
grant select (ai_credit_chf) on profiles to authenticated;
