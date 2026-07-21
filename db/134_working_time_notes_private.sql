-- Sautero — SECURITY FIX (2026-07-17 audit): the `working-time-notes` storage bucket held
-- uploaded employment contracts / working-time notes (wages, hours, personal terms) but was
-- created PUBLIC via the dashboard, and its SELECT policy allowed ANY authenticated user to read
-- ANY file in the bucket. Two problems at once:
--   1. public bucket  -> files served at a shareable URL with NO auth at all,
--   2. bucket-wide SELECT -> even signed-in users could read colleagues' contracts.
--
-- Root cause it escaped every check: buckets/storage policies were configured in the Supabase
-- UI, not in a migration, so audit_db.py never saw them. From now on all storage config lives
-- here in version control (and audit_db.py gained a storage-security check — see that script).
--
-- Fix: private bucket + owner-only access on every verb. Files are stored under a folder named
-- by the owner's uid ("{auth.uid()}/{date}.ext"), so (storage.foldername(name))[1] = auth.uid()
-- is the ownership test. The app now reads via short-lived signed URLs (createSignedUrl), not
-- public ones.

update storage.buckets set public = false where id = 'working-time-notes';

drop policy if exists "read working time note photos" on storage.objects;
create policy "read working time note photos" on storage.objects
  for select using (
    bucket_id = 'working-time-notes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Re-assert the write verbs owner-scoped too (they already were, but pin them here so the whole
-- bucket's policy set lives in one migration and can't drift silently in the UI again).
drop policy if exists "upload own working time note photos" on storage.objects;
create policy "upload own working time note photos" on storage.objects
  for insert with check (
    bucket_id = 'working-time-notes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "update own working time note photos" on storage.objects;
create policy "update own working time note photos" on storage.objects
  for update using (
    bucket_id = 'working-time-notes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "delete own working time note photos" on storage.objects;
create policy "delete own working time note photos" on storage.objects
  for delete using (
    bucket_id = 'working-time-notes'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
