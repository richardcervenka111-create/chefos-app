-- 145: Add Team Member (Richard, 18.7.) — a kitchen's OWN admin can mint a join code for
-- THEIR OWN kitchen. Until now regenerate_join_code required the create_teams grant (or super
-- admin), which is the "create NEW kitchens" capability — but a company admin whose kitchen
-- already exists (e.g. protonmail admin of their T1 kitchen) only needs to ADD PEOPLE to it.
-- Creating kitchens stays with the Head Admin (Add Company / Create Team); minting a join code
-- for a kitchen you administer is now its own, narrower right.
create or replace function regenerate_join_code(p_kitchen_id uuid)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_code text;
begin
  if not (
    _is_team_creator()
    or exists (
      select 1 from profiles
      where id = auth.uid()
        and kitchen_id = p_kitchen_id
        and (is_admin or (admin_perms->>'company_admin')::boolean is true)
    )
  ) then
    raise exception 'Not authorized to manage team codes';
  end if;
  v_code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
  update kitchens set join_code_hash = encode(digest(v_code, 'sha256'), 'hex') where id = p_kitchen_id;
  return v_code;
end;
$$;
grant execute on function regenerate_join_code(uuid) to authenticated;
