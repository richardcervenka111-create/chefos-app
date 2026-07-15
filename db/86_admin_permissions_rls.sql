-- ChefOS -- wire the granular admin_perms (db/85) into actual RLS policies, and fix a real
-- bug found while doing this: email_contacts' INSERT policy required is_admin, but the app
-- inserts an access_request-sourced row from renderTeamGate() for EVERY new signup, almost
-- none of whom are admins -- meaning most access-request contacts have been silently failing
-- to log since db/82 shipped (swallowed by the best-effort .then(), so nothing looked broken).
--
-- STAGING FIRST -- this rewrites live RLS policies (same class as db/62/db/80/db/81's lesson).

-- ---------- kitchen_invites (db/81): manage_invites can also create/revoke, not just is_admin
drop policy if exists "admin creates kitchen invite" on kitchen_invites;
create policy "create kitchen invite" on kitchen_invites
  for insert with check (
    kitchen_id in (
      select kitchen_id from profiles
      where id = auth.uid() and (is_admin or (admin_perms->>'manage_invites')::boolean)
    )
  );

drop policy if exists "admin revokes kitchen invite" on kitchen_invites;
create policy "revoke kitchen invite" on kitchen_invites
  for update using (
    kitchen_id in (
      select kitchen_id from profiles
      where id = auth.uid() and (is_admin or (admin_perms->>'manage_invites')::boolean)
    )
  );

-- ---------- profiles: manage_team can also remove a kitchen member (db/53's admin-only policy)
drop policy if exists "admin remove kitchen member" on profiles;
create policy "remove kitchen member" on profiles
  for update using (
    kitchen_id is not null and kitchen_id in (
      select kitchen_id from profiles p2
      where p2.id = auth.uid() and (p2.is_admin or (p2.admin_perms->>'manage_team')::boolean)
    )
  );

-- ---------- email_contacts (db/82): fix the real bug above + wire view_email_contacts
drop policy if exists "admin writes email contacts" on email_contacts;
create policy "insert own access-request or admin/invite-permission" on email_contacts
  for insert with check (
    (source = 'access_request' and lower(email) = lower(auth.jwt() ->> 'email'))
    or exists (
      select 1 from profiles
      where id = auth.uid() and (is_admin or (admin_perms->>'manage_invites')::boolean)
    )
  );

drop policy if exists "admin reads email contacts" on email_contacts;
create policy "read email contacts" on email_contacts
  for select using (
    exists (
      select 1 from profiles
      where id = auth.uid() and (is_admin or (admin_perms->>'view_email_contacts')::boolean)
    )
  );

drop policy if exists "admin updates email contacts" on email_contacts;
create policy "update email contacts" on email_contacts
  for update using (
    exists (
      select 1 from profiles
      where id = auth.uid() and (is_admin or (admin_perms->>'view_email_contacts')::boolean)
    )
  );

-- ---------- access_requests (db/34): approve_access can also review requests
drop policy if exists "admin review requests" on access_requests;
create policy "review access requests" on access_requests
  for update using (
    exists (
      select 1 from profiles
      where id = auth.uid() and (is_admin or (admin_perms->>'approve_access')::boolean)
    )
  );

-- ---------- profiles: Admin Directory needs to list/search EVERY profile, not just same-kitchen
-- teammates (db/53/db/55) or your own row (db/01) -- the only two SELECT policies that existed
-- before this. Kept super-admin-only (not extended to any admin_perms key) since it's the one
-- policy that can see every kitchen's people at once -- platform-wide read, Richard only.
create policy "super-admin reads all profiles" on profiles
  for select using (
    exists (select 1 from profiles me where me.id = auth.uid() and me.is_admin)
  );
