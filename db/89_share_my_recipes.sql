-- Sautero -- Share My Recipes (Richard, 16.7., bod 3/6): "urob to tak ako si napísal" -- build
-- it exactly as proposed: only a person's own recipes (created_by = them), a read-only view
-- (never a copy/import into the viewer's own kitchen), gated by an opt-in per-user toggle, with
-- a narrow cross-kitchen RLS carve-out limited to actual chef_connections (db/84) friends.
--
-- This was the "coming soon" placeholder in the Share QR Code sheet (bod 6, 15.7.).
--
-- Safe straight to production: one additive column + one new, purely additive SELECT policy
-- (Postgres combines multiple permissive policies for the same command with OR -- this adds a
-- second way to see a recipe, it can never take away the existing "read kitchen recipes" read
-- from db/01).

alter table profiles add column if not exists recipes_shared boolean not null default false;

-- db/62 locked profiles down to a column-level SELECT allow-list -- every new profiles column
-- MUST be added to it or every query naming the column fails outright for the authenticated
-- role (invisible in the SQL editor; this exact omission for admin_perms/email in db/85 caused
-- the 2026-07-16 super-admin lockout, fixed in db/90). Never skip this line again.
grant select (recipes_shared) on profiles to authenticated;

-- A recipe becomes visible outside its own kitchen only if: it's Sautero/Moje-shelf-owned by a
-- real person (created_by is not null -- Firemné/teammate recipes never qualify, since sharing
-- a colleague's work without their own opt-in would defeat the whole point of this being
-- opt-in), that person has turned sharing on, AND the viewer is one of their actual
-- chef_connections. Two people never "connecting" means never seeing each other's recipes,
-- no matter what the toggle says.
create policy "read connected shared recipes" on recipes
  for select using (
    created_by is not null
    and created_by <> auth.uid()
    and exists (
      select 1 from profiles p where p.id = recipes.created_by and p.recipes_shared
    )
    and exists (
      select 1 from chef_connections c
      where (c.user_a = auth.uid() and c.user_b = recipes.created_by)
         or (c.user_b = auth.uid() and c.user_a = recipes.created_by)
    )
  );

-- The "My Connections" list needs a name/email to show for each connection -- but profiles
-- also holds genuinely sensitive rows (contracted_hours_per_week, contract_advisory_points --
-- an AI-read employment contract review, age, gender). A plain RLS policy on profiles can't
-- carve out "just these 4 safe columns", so this uses the standard Postgres pattern instead: a
-- SECURITY DEFINER function that internally bypasses RLS but only ever returns the narrow safe
-- slice, for actual chef_connections only. Nobody's contract data or age/gender is reachable
-- through this, no matter what.
create or replace function get_my_connections()
returns table(id uuid, full_name text, email text, recipes_shared boolean)
language sql
security definer
set search_path = public
stable
as $$
  select p.id, p.full_name, p.email, p.recipes_shared
  from profiles p
  where p.id in (
    select case when c.user_a = auth.uid() then c.user_b else c.user_a end
    from chef_connections c
    where c.user_a = auth.uid() or c.user_b = auth.uid()
  );
$$;

grant execute on function get_my_connections() to authenticated;
