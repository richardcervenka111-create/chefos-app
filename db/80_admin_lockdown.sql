-- ChefOS -- Admin lockdown (Richard, 15.7.): nobody has admin functions except
-- richard.cervenka@icloud.com, until Richard personally approves someone.
--
-- STAGING FIRST -- this UPDATEs live data (resets is_admin) and adds a trigger.
--
-- Security finding that makes the trigger NON-OPTIONAL (health check follow-up):
-- the "update own profile" policy (db/34) lets any user UPDATE their own profiles row
-- with no column restriction -- meaning anyone could set is_admin = true on themselves.
-- Privilege escalation, open since db/34. We deliberately do NOT fix it with column-level
-- GRANT/REVOKE (that approach locked owners out of their own rows once before -- db/62 ->
-- db/68 emergency). A trigger distinguishes exactly what column grants cannot.
--
-- App-side counterpart (same commit): creating a kitchen no longer self-grants is_admin.

-- 1) One super-admin, everyone else demoted.
update profiles set is_admin = false
where id not in (select id from auth.users where lower(email) = 'richard.cervenka@icloud.com');

update profiles set is_admin = true
where id in (select id from auth.users where lower(email) = 'richard.cervenka@icloud.com');

-- 2) Permanent guard: is_admin can only change when the acting party is the super-admin
--    or a non-JWT context (SQL editor / service role -- how Richard runs migrations).
create or replace function guard_is_admin_changes()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.is_admin is distinct from old.is_admin then
    if auth.uid() is null then
      return new; -- SQL editor / service role: allowed (Richard's manual operations)
    end if;
    if auth.uid() in (select id from auth.users where lower(email) = 'richard.cervenka@icloud.com') then
      return new; -- the super-admin himself, acting from inside the app
    end if;
    raise exception 'is_admin can only be changed by the ChefOS super-admin';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_guard_is_admin on profiles;
create trigger trg_guard_is_admin
  before update on profiles
  for each row execute function guard_is_admin_changes();

-- Verify afterwards:
--   select u.email, p.is_admin from profiles p join auth.users u on u.id = p.id
--   where p.is_admin;                         -- expect exactly one row (the icloud account)
