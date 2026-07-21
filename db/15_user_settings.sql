-- Sautero — Phase 1b: stores each person's own Anthropic API key, for photo-scan.
-- Personal, not kitchen-scoped — nobody but the owning user can ever read or write their
-- own row (not even other members of the same kitchen). The key is typed directly into the
-- app's own settings screen by the user themselves and never passes through anyone else.
create table if not exists user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  anthropic_api_key text,
  updated_at timestamptz not null default now()
);

alter table user_settings enable row level security;

create policy "read own settings" on user_settings
  for select using (auth.uid() = user_id);
create policy "write own settings" on user_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
