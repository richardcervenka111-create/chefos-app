-- ChefOS — confidentiality acknowledgement (2026-07-13).
--
-- Richard wants every user to explicitly agree not to share a kitchen's recipes/prices/data
-- outside the app before they can use it. This is an append-only log (never updated or
-- deleted) rather than a mutable flag on profiles, so there's a permanent, timestamped record
-- of exactly which version of the confidentiality text a given user agreed to, and when — the
-- same reasoning as check_list_audit_log (db/54). The app gates entry in startApp() (app/
-- index.html) on the presence of a row here matching CONFIDENTIALITY_VERSION; bumping that
-- constant after a material text change makes everyone re-agree without losing the old record.

create table if not exists confidentiality_acceptances (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) not null,
  kitchen_id uuid references kitchens(id),
  version text not null,
  accepted_at timestamptz not null default now()
);
create index if not exists confidentiality_acceptances_user_idx on confidentiality_acceptances(user_id, version);

alter table confidentiality_acceptances enable row level security;

create policy "read own acceptance" on confidentiality_acceptances
  for select using (user_id = auth.uid());

create policy "insert own acceptance" on confidentiality_acceptances
  for insert with check (user_id = auth.uid());
