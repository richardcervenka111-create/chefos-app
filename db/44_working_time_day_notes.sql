-- Sautero — Working Time: a note per calendar day (not per check-in entry), auto-saved, with an
-- optional photo. Richard's own example: something worth remembering about a specific day at
-- work (an incident, a reason hours were off, anything) — independent of how many check-in
-- entries that day happens to have.
create table if not exists working_time_day_notes (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  user_id uuid not null references auth.users(id),
  note_date date not null,
  note text,
  photo_url text,
  updated_at timestamptz not null default now(),
  unique (user_id, note_date)
);
alter table working_time_day_notes enable row level security;

create policy "read own day notes" on working_time_day_notes
  for select using (user_id = auth.uid());
create policy "insert own day notes" on working_time_day_notes
  for insert with check (user_id = auth.uid() and kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update own day notes" on working_time_day_notes
  for update using (user_id = auth.uid());
create policy "delete own day notes" on working_time_day_notes
  for delete using (user_id = auth.uid());

-- Storage bucket for the optional photo attached to a day note. Public bucket (same trust
-- level as everything else in this pilot app — no sensitive payroll data in the photo itself,
-- just an optional visual note); write access is still restricted to the owning user via the
-- folder-name-is-your-user-id convention below.
insert into storage.buckets (id, name, public)
values ('working-time-notes', 'working-time-notes', true)
on conflict (id) do nothing;

create policy "read working time note photos" on storage.objects
  for select using (bucket_id = 'working-time-notes');
create policy "upload own working time note photos" on storage.objects
  for insert with check (bucket_id = 'working-time-notes' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "update own working time note photos" on storage.objects
  for update using (bucket_id = 'working-time-notes' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "delete own working time note photos" on storage.objects
  for delete using (bucket_id = 'working-time-notes' and auth.uid()::text = (storage.foldername(name))[1]);
