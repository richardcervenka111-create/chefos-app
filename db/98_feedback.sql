-- Sautero — user feedback (Richard, 16.7., bod 4): "Pripomienky od ľudí budem mať tiež v
-- priečinku admin" — anyone can send free-text feedback from Settings; Head Admin reads it in
-- a new Admin tile. Deliberately simple (no status/reply workflow) — just a stream, newest first.

-- created_by references profiles(id), not auth.users(id) directly, so the app can embed
-- `profiles:created_by(full_name, email)` in one query (PostgREST needs a direct FK to do that).
create table if not exists feedback (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  created_by uuid references profiles(id),
  message text not null,
  created_at timestamptz not null default now()
);

alter table feedback enable row level security;

-- Anyone can send feedback about their own kitchen.
create policy "send own feedback" on feedback
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    and created_by = auth.uid()
  );

-- Only Head Admin reads it (platform-wide, not just their own kitchen — Richard is the one
-- actually acting on this, same reasoning as Email Contacts/Access Requests being his alone).
create policy "head admin reads all feedback" on feedback
  for select using (is_super_admin());
