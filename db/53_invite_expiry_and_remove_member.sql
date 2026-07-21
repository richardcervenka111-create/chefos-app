-- Sautero — expiring/revocable invite links + ability to remove a team member (2026-07-13).
-- Backlog v2 (CTO + Solution Architect): the invite link was literally the kitchen's own id —
-- never expires, can't be revoked without breaking the kitchen itself, and there was no way to
-- remove someone from a team at all once they joined.

-- A real, separate invite token (not the kitchen's own id) — revocable and expiring on its own,
-- with no effect on the kitchen itself either way.
create table if not exists kitchen_invites (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  revoked boolean not null default false
);
alter table kitchen_invites enable row level security;

-- Has to be readable by someone who isn't a team member yet (they're about to use the link to
-- decide whether to join) — same reasoning as the existing "read any kitchen name" policy on
-- kitchens itself.
create policy "read any invite" on kitchen_invites
  for select using (auth.uid() is not null);
create policy "create kitchen invite" on kitchen_invites
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "revoke own kitchen invite" on kitchen_invites
  for update using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );

-- Team members need to be able to see each other's names at all — profiles previously only
-- exposed your own row to yourself, so there was no way to render a member list in the first
-- place, separate from the ability to remove anyone.
create policy "read kitchen teammates" on profiles
  for select using (
    kitchen_id is not null and kitchen_id in (
      select kitchen_id from profiles p2 where p2.id = auth.uid()
    )
  );

-- Admin-only: remove a member from their own kitchen by clearing their kitchen_id — same state
-- as a brand-new signup, they can create or join a (possibly different) kitchen afterward.
create policy "admin remove kitchen member" on profiles
  for update using (
    kitchen_id is not null and kitchen_id in (
      select kitchen_id from profiles p2 where p2.id = auth.uid() and p2.is_admin
    )
  );
