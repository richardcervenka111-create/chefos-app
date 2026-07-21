-- 139: per-user AI usage log (Richard, 17.7.2026: "vieš trackovať koľko ktorý užívateľ minie?").
--
-- The Claude Platform dashboard only ever sees Sautero's one central API key — it can never
-- split spend by app user. This table is that split: claude-proxy inserts one row per
-- successful Anthropic call (who, model, tokens, computed cost), for EVERY account type,
-- including while ai_unlimited_testing_mode is on (the credit gate skips billing then, but
-- tracking must still see everything).
--
-- Writes happen ONLY via the edge function's service-role client — no client-side insert/
-- update/delete policy exists on purpose. Reads: each user their own rows; Head Admin all
-- (feeds the Admin → AI Usage screen).

create table if not exists ai_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kitchen_id uuid,
  feature text,
  model text not null default '',
  input_tokens integer not null default 0,
  output_tokens integer not null default 0,
  cost_usd numeric(12,6) not null default 0,
  created_at timestamptz not null default now()
);

alter table ai_usage enable row level security;

drop policy if exists ai_usage_select_own on ai_usage;
create policy ai_usage_select_own on ai_usage
  for select using (user_id = auth.uid());

drop policy if exists ai_usage_select_head_admin on ai_usage;
create policy ai_usage_select_head_admin on ai_usage
  for select using (
    exists (select 1 from profiles where id = auth.uid() and is_admin)
  );

create index if not exists ai_usage_user_created_idx on ai_usage (user_id, created_at desc);
create index if not exists ai_usage_created_idx on ai_usage (created_at desc);
