-- Sautero -- Email contacts database (Richard, 15.7. late night, bod 8).
--
-- Interpretation (stated plainly since "vytvor databazu emailov" is otherwise ambiguous):
-- a single admin-viewable table of every email address Sautero has ever touched, with WHY it's
-- there -- useful for founding-member outreach later (monetization plan) and because right now
-- nothing records who an invite email actually went to (sendInviteByEmail() calls Supabase's
-- OTP sender directly and never saved the address anywhere in our own tables -- a real gap,
-- closed by this same commit's app-side change).
--
-- Safe straight to production: new table, no data mutation.

-- Uniqueness is plain (email, source) -- no expression index (lower()/coalesce()) -- because
-- Supabase's client-side .upsert({onConflict:...}) can only target a real column-list unique
-- constraint, not an expression index. App call sites always lowercase the email themselves
-- before writing here (matching the convention access_requests already relies on). kitchen_id
-- stays a plain (non-unique) column: if the same email is later invited to a second kitchen,
-- that upsert updates this same row's kitchen_id/last_seen_at rather than adding a second row
-- -- a deliberate v1 simplification, not a full per-kitchen contact history.
create table if not exists email_contacts (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  source text not null check (source in ('access_request', 'invite_sent', 'signup')),
  kitchen_id uuid references kitchens(id),  -- which kitchen this contact relates to, if any
  status text not null default 'new' check (status in ('new', 'joined', 'declined')),
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  notes text,
  unique (email, source)
);

alter table email_contacts enable row level security;

-- Admin-only, kitchen-wide read/write is deliberately NOT how this works -- this is
-- Sautero-operator data (Richard's own outreach list), not per-kitchen operational data, so it
-- has no kitchen_id tenant scoping requirement the way most tables do.
create policy "admin reads email contacts" on email_contacts
  for select using (exists (select 1 from profiles where id = auth.uid() and is_admin));
create policy "admin writes email contacts" on email_contacts
  for insert with check (exists (select 1 from profiles where id = auth.uid() and is_admin));
create policy "admin updates email contacts" on email_contacts
  for update using (exists (select 1 from profiles where id = auth.uid() and is_admin));

-- Backfill: every email that has already requested access, so the list isn't empty on day one.
insert into email_contacts (email, source, status, first_seen_at, last_seen_at)
select lower(email), 'access_request',
  case status when 'approved' then 'joined' when 'denied' then 'declined' else 'new' end,
  requested_at, coalesce(reviewed_at, requested_at)
from access_requests
on conflict (email, source) do nothing;
