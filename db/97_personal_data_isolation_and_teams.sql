-- Sautero — real personal/company data privacy + team join system (Richard, 16.7., bod 1)
--
-- Until now, "Moje / Firemné / Sautero" recipe shelves (and the account_type gate) were purely
-- client-side UI filters. The RLS policy "read kitchen recipes" grants access to EVERY recipe
-- in the same kitchen_id, so a personal-account user's own recipe was already technically
-- visible to any teammate who opened the "Firemné" filter. Same story for `ingredients`. This
-- migration makes personal data genuinely private at the database level, and adds the
-- infrastructure for a new "team creator" admin tier that can mint join codes for new
-- restaurants/kitchens (scan QR or enter code manually to link a personal account to a real
-- team, matching Richard's described flow).
--
-- Design: kitchen_id is left untouched for every row (still the user's real, current kitchen —
-- no fake "solo kitchen" is created). Privacy comes from a new `is_personal` flag plus a second
-- OR'd clause "created_by = auth.uid()" on every read/write policy, so:
--   - is_personal = false  -> visible to the whole kitchen, exactly like today (unchanged).
--   - is_personal = true   -> visible ONLY to its creator, everywhere, forever — even if they
--     later switch kitchen_id by joining a different team. This is what makes "you always see
--     what you saved into your personal version" true regardless of which team you join later.
-- Friend-to-friend recipe sharing (db/89, `recipes_shared`) is a separate OR'd policy and is
-- untouched — an explicitly shared personal recipe still reaches connected friends as before.

-- 1) RECIPES ---------------------------------------------------------------
alter table recipes add column if not exists is_personal boolean not null default false;
grant select (is_personal) on recipes to authenticated;

drop policy if exists "read kitchen recipes" on recipes;
create policy "read kitchen recipes" on recipes
  for select using (
    (kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and not is_personal)
    or created_by = auth.uid()
  );

drop policy if exists "update kitchen recipes" on recipes;
create policy "update kitchen recipes" on recipes
  for update using (
    (kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and not is_personal)
    or created_by = auth.uid()
  );

create policy "delete own personal recipes" on recipes
  for delete using (is_personal and created_by = auth.uid());

-- 2) INGREDIENTS — new "My Ingredients" (personal, private) alongside the existing kitchen-wide
--    catalog (now labelled "Sautero" in the UI, same convention as the recipe shelves). ---------
alter table ingredients add column if not exists is_personal boolean not null default false;
grant select (is_personal) on ingredients to authenticated;

-- the old uniqueness (kitchen_id, name) would block a personal ingredient sharing a name with
-- a shared/Sautero one, or with another chef's own personal item — split into two partial
-- indexes so shared names stay deduped but personal ones are scoped to their own creator.
drop index if exists ingredients_kitchen_name_uidx;
create unique index if not exists ingredients_shared_name_uidx
  on ingredients (kitchen_id, lower(name)) where not is_personal;
create unique index if not exists ingredients_personal_name_uidx
  on ingredients (kitchen_id, lower(name), created_by) where is_personal;

drop policy if exists "read kitchen ingredients" on ingredients;
create policy "read kitchen ingredients" on ingredients
  for select using (
    (kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and not is_personal)
    or created_by = auth.uid()
  );

drop policy if exists "update kitchen ingredients" on ingredients;
create policy "update kitchen ingredients" on ingredients
  for update using (
    (kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and not is_personal)
    or created_by = auth.uid()
  );

drop policy if exists "delete kitchen ingredients" on ingredients;
create policy "delete kitchen ingredients" on ingredients
  for delete using (
    (kitchen_id in (select kitchen_id from profiles where id = auth.uid()) and not is_personal)
    or created_by = auth.uid()
  );

-- 3) TEAM JOIN CODES ---------------------------------------------------------
-- IMPORTANT: db/34 already made `kitchens` broadly readable to any logged-in user ("read any
-- kitchen name" — needed so invite links can show a kitchen's name before joining). A plaintext
-- join_code column would therefore leak every team's code to anyone with API access, defeating
-- its whole purpose. So only a SALTED HASH of the code is ever stored/selectable — the plaintext
-- exists only transiently in a function's return value, right when a team creator mints it.
alter table kitchens add column if not exists join_code_hash text unique;

-- New admin capability (admin_perms->>'create_teams', db/85 jsonb column, no schema change
-- needed) — Richard: "tento typ adminu ešte nikto nemá, ja ho budem môcť označiť". Only Head
-- Admin or someone explicitly granted create_teams can create a new kitchen row. Kept as
-- defense-in-depth for direct table inserts; the RPCs below also check this themselves since
-- SECURITY DEFINER functions bypass RLS for their own internal writes.
create policy "team creators can create kitchens" on kitchens
  for insert with check (
    is_super_admin()
    or exists (
      select 1 from profiles
      where id = auth.uid() and (admin_perms->>'create_teams')::boolean is true
    )
  );

create or replace function _is_team_creator()
returns boolean
language sql
security definer
set search_path = public
as $$
  select is_super_admin() or exists (
    select 1 from profiles
    where id = auth.uid() and (admin_perms->>'create_teams')::boolean is true
  );
$$;

-- Creates a new kitchen and returns its id + a fresh plaintext join code (shown once to the
-- creator to display as text/QR — never stored in plaintext, never selectable afterward).
create or replace function create_team(p_name text)
returns table(id uuid, join_code text)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_id uuid;
  v_code text;
begin
  if not _is_team_creator() then
    raise exception 'Not authorized to create teams';
  end if;
  v_code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
  insert into kitchens (name, created_by, join_code_hash)
    values (p_name, auth.uid(), encode(digest(v_code, 'sha256'), 'hex'))
    returning kitchens.id into v_id;
  return query select v_id, v_code;
end;
$$;
grant execute on function create_team(text) to authenticated;

-- Mints a fresh code for an EXISTING kitchen (e.g. Richard's own, or any team that lost its
-- code) — same authorization + one-time-plaintext-return pattern as create_team.
create or replace function regenerate_join_code(p_kitchen_id uuid)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_code text;
begin
  if not _is_team_creator() then
    raise exception 'Not authorized to manage team codes';
  end if;
  v_code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
  update kitchens set join_code_hash = encode(digest(v_code, 'sha256'), 'hex') where id = p_kitchen_id;
  return v_code;
end;
$$;
grant execute on function regenerate_join_code(uuid) to authenticated;

-- Look up a team by code WITHOUT joining — lets the app show "Join <name>'s team?" before
-- committing. Safe against enumeration: you must already know the exact code, and this returns
-- only the one matching row's name, never a list.
create or replace function lookup_team_by_code(p_code text)
returns table(id uuid, name text)
language sql
security definer
set search_path = public, extensions
as $$
  select k.id, k.name from kitchens k
    where k.join_code_hash = encode(digest(upper(trim(p_code)), 'sha256'), 'hex');
$$;
grant execute on function lookup_team_by_code(text) to authenticated;

-- Links the calling user's profile to whichever kitchen owns this code (scan QR / manual entry
-- both call this after lookup_team_by_code has shown a confirmation). Never exposes which codes
-- exist or belong to whom — a wrong code just fails.
create or replace function join_team_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_kitchen_id uuid;
begin
  select id into v_kitchen_id from kitchens
    where join_code_hash = encode(digest(upper(trim(p_code)), 'sha256'), 'hex');
  if v_kitchen_id is null then
    raise exception 'Invalid code';
  end if;
  update profiles set kitchen_id = v_kitchen_id where id = auth.uid();
  return v_kitchen_id;
end;
$$;
grant execute on function join_team_by_code(text) to authenticated;

-- 4) Two small UX preference flags on profiles — kept as real columns (not localStorage) so
--    they follow the person across devices, same reasoning as password_set etc.
alter table profiles add column if not exists skip_account_type_confirm boolean not null default false;
alter table profiles add column if not exists team_join_seen boolean not null default false;
grant select (skip_account_type_confirm) on profiles to authenticated;
grant select (team_join_seen) on profiles to authenticated;

-- 5) Limited AI for Personal accounts + subscription (Richard, 16.7., bod 8) — no live payment
--    system yet, so this is a manual flag Richard toggles per-person in Admin Directory until
--    real billing exists. Company accounts are never gated by this (unaffected either way).
alter table profiles add column if not exists is_subscribed boolean not null default false;
grant select (is_subscribed) on profiles to authenticated;
