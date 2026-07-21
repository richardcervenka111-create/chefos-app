-- Sautero — in-app feedback/bug reports (2026-07-14).
--
-- Richard: the old Feedback/Report-a-bug buttons used mailto: links to his personal Gmail,
-- which (a) named him directly, (b) only worked if the phone had a configured mail app, and
-- (c) depended on a hello@sautero-style address that doesn't exist yet. This replaces both with
-- a plain in-app window: type a message, submit, done — no external app involved at all. Once
-- a shared inbox/domain exists, an Edge Function trigger can forward new rows there; until
-- then, read this table directly via the SQL editor.

create table if not exists feedback_reports (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid references kitchens(id),
  user_id uuid references auth.users(id),
  type text not null check (type in ('feedback','bug')),
  message text not null,
  context jsonb,
  created_at timestamptz not null default now()
);
create index if not exists feedback_reports_created_idx on feedback_reports(created_at desc);

alter table feedback_reports enable row level security;

create policy "insert own feedback report" on feedback_reports
  for insert with check (auth.uid() is not null);
