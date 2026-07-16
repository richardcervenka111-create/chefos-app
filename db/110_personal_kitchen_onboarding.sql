-- ChefOS — personal onboarding via friend invite (Richard, 16.7., follow-up to the "Join Mr.
-- Woof woof" report).
--
-- Until now the Add Friend QR/email doubled as a kitchen invite, so a brand-new person invited
-- by a friend got pulled INTO the inviter's kitchen — seeing their kitchen name at signup and
-- their Check List projects (the "Burito" he saw) once inside. Richard's new rule: a friend
-- invite from a PERSONAL account is purely social — the new person gets their OWN kitchen,
-- starting empty (Check List shows only "+ Add Project"), with the standard ChefOS shelves
-- (the kitchens-insert triggers from db/74/db/87 seed ingredients + recipes automatically).
--
-- Why an RPC: db/101 deliberately closed direct kitchen creation to team-creator roles only.
-- This is the one narrow, safe exception — a person with NO kitchen at all may get exactly one
-- created for themselves. Someone who already has a kitchen just gets their existing id back
-- (idempotent, never moves anyone anywhere).

create or replace function ensure_personal_kitchen(p_name text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing uuid;
  v_kitchen_id uuid;
  v_name text;
begin
  select kitchen_id into v_existing from profiles where id = auth.uid();
  if v_existing is not null then
    return v_existing;
  end if;
  v_name := coalesce(nullif(trim(p_name), ''), 'My Kitchen');
  insert into kitchens (name, created_by) values (v_name, auth.uid()) returning id into v_kitchen_id;
  update profiles set kitchen_id = v_kitchen_id where id = auth.uid();
  return v_kitchen_id;
end;
$$;
grant execute on function ensure_personal_kitchen(text) to authenticated;
