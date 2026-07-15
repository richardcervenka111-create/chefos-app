-- ChefOS -- Connections (bod 6, 15.7. late night): "Add Friend" via personal QR, backing the
-- new Connections hub (renamed + rebuilt from My Team).
--
-- Deliberately NOT kitchen-scoped -- a connection is between two PEOPLE, not two kitchens, so
-- it's whitelisted in scripts/audit_db.py the same way profiles/favorites are. Scanning
-- someone's personal QR in person is treated as mutual consent (like scanning a Snapchat/
-- Instagram code) -- no separate pending/accept step, the row is created 'accepted' directly.
--
-- Safe straight to production: new table, no data mutation.

create table if not exists chef_connections (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references auth.users(id),
  user_b uuid not null references auth.users(id),
  status text not null default 'accepted' check (status in ('accepted')),
  created_at timestamptz not null default now(),
  check (user_a <> user_b)
);
-- One connection row per pair, regardless of who scanned whom -- store canonical order so
-- (A,B) and (B,A) can never both exist.
create unique index if not exists chef_connections_pair_key
  on chef_connections (least(user_a, user_b), greatest(user_a, user_b));

alter table chef_connections enable row level security;

create policy "read own connections" on chef_connections
  for select using (auth.uid() = user_a or auth.uid() = user_b);
create policy "create connection as either party" on chef_connections
  for insert with check (auth.uid() = user_a or auth.uid() = user_b);
create policy "remove own connection" on chef_connections
  for delete using (auth.uid() = user_a or auth.uid() = user_b);
