-- Sautero — multi-team support (each restaurant is its own "kitchen") + a manual access gate
-- for the closed public trial. Two independent things:
--
-- 1) TEAMS: `kitchens` + `profiles.kitchen_id` already scoped every table's RLS by kitchen
--    (see 01_schema.sql) — that part didn't need to change. What was missing: nobody could
--    create a new kitchen or change their own kitchen_id from the client (no RLS policy
--    allowed it), and every new signup was auto-attached to "the one kitchen that exists so
--    far" (fine for a single pilot kitchen, wrong now that different restaurants need their
--    own separate team). New signups now get kitchen_id = null and pick one themselves in the
--    app (create their own, or join one via an invite link/QR that carries the kitchen's id).
--
-- 2) ACCESS GATE: Richard wants to manually confirm every email before it can actually use
--    the app (closed trial — friends and acquaintances, not an open public signup). A new
--    `access_requests` table tracks this; only he (is_admin = true) can approve/deny. This is
--    separate from team membership — once approved, a person can freely create or join any
--    team without needing a second approval.
--
-- Existing users (Richard + the two pilot testers) are unaffected: they already have a
-- kitchen_id set, so the gate only applies to brand-new signups going forward.

-- ---------- 1) Teams ----------

alter table kitchens add column if not exists created_by uuid references auth.users(id);

-- Any logged-in person can create their own new kitchen/team.
create policy "create kitchen" on kitchens
  for insert with check (auth.uid() is not null);

-- Kitchen names need to be readable by anyone logged in (not just members) so an invite link
-- can show "Join <name>'s kitchen?" before the person has actually joined it.
create policy "read any kitchen name" on kitchens
  for select using (auth.uid() is not null);

-- A person can update their own profile row — needed to set their own kitchen_id when
-- creating or joining a team.
create policy "update own profile" on profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- New signups no longer get auto-attached to the first kitchen that exists — they pick
-- (create or join) inside the app instead.
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, kitchen_id) values (new.id, null);
  return new;
end;
$$ language plpgsql security definer;

-- ---------- 2) Access gate ----------

alter table profiles add column if not exists is_admin boolean not null default false;

update profiles set is_admin = true
where id = (select id from auth.users where email = 'richard.cervenka111@gmail.com');

create table if not exists access_requests (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  status text not null default 'pending' check (status in ('pending','approved','denied')),
  requested_at timestamptz not null default now(),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz
);
alter table access_requests enable row level security;

-- Someone can only ever file a request for their own logged-in email.
create policy "request own access" on access_requests
  for insert with check (
    auth.uid() is not null and lower(email) = lower(auth.jwt() ->> 'email')
  );

-- A person can see their own request's status; an admin can see everyone's.
create policy "read own or admin" on access_requests
  for select using (
    lower(email) = lower(auth.jwt() ->> 'email')
    or exists (select 1 from profiles where id = auth.uid() and is_admin)
  );

-- Only an admin can approve/deny.
create policy "admin review requests" on access_requests
  for update using (
    exists (select 1 from profiles where id = auth.uid() and is_admin)
  );
