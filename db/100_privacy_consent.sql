-- Sautero — Privacy & Data Protection consent (Richard, 16.7., bod 3).
--
-- Same exact mechanism as confidentiality_acceptances (db/60, 2026-07-13): an append-only,
-- versioned acceptance log, gated in startApp() before someone can use the app, bumping the
-- version forces EVERYONE (including people already using the app) to re-agree on their next
-- login. Kept as its own table/gate rather than folded into the confidentiality one — they
-- cover different things: confidentiality is "don't leak your kitchen's data", this is "here's
-- what Sautero itself collects about you and why" (GDPR/Swiss nFADP-style data-processing
-- consent). See /security/PRIVACY_POLICY_DRAFT.html for the full text this summarizes — that
-- document is a DRAFT for a lawyer to review, not reviewed legal advice.

create table if not exists privacy_acceptances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) not null,
  kitchen_id uuid references kitchens(id),
  version text not null,
  accepted_at timestamptz not null default now()
);
create index if not exists privacy_acceptances_user_idx on privacy_acceptances(user_id, version);

alter table privacy_acceptances enable row level security;

create policy "read own privacy acceptance" on privacy_acceptances
  for select using (user_id = auth.uid());

create policy "insert own privacy acceptance" on privacy_acceptances
  for insert with check (user_id = auth.uid());
