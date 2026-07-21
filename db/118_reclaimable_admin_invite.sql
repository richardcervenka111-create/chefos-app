-- Sautero — "nech sa to už nestáva" (Richard, 16.7. večer): the admin-invite claim is now
-- tolerant of the exact failure that hit sautero@protonmail.com — a single-use invite consumed
-- by an earlier open (mail previews, double taps), leaving the person inside the kitchen but
-- without the role.
--
-- New rule: a used/expired admin invite can still grant the role IF BOTH hold:
--   1. the caller is already a member of that invite's kitchen (they got in via the link), and
--   2. the kitchen has NO company admin yet.
-- Condition 2 is what keeps this safe: the moment the intended person holds the role, the
-- burnt link grants nothing to anyone else, ever. Before that, whoever entered the kitchen
-- through the invite IS the intended person (the email went to exactly one address).

create or replace function claim_company_admin(p_invite uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite record;
begin
  select * into v_invite from kitchen_invites
    where id = p_invite and grants_company_admin;
  if v_invite is null then
    return false;
  end if;
  -- Caller must already be in the invite's kitchen.
  if not exists (select 1 from profiles where id = auth.uid() and kitchen_id = v_invite.kitchen_id) then
    return false;
  end if;
  -- A fresh invite always works; a consumed/expired one only while the seat is still empty.
  if (v_invite.revoked or v_invite.expires_at <= now())
     and exists (
       select 1 from profiles
       where kitchen_id = v_invite.kitchen_id
         and (admin_perms->>'company_admin')::boolean is true
     ) then
    return false;
  end if;
  update profiles set
    admin_perms = coalesce(admin_perms, '{}'::jsonb)
      || '{"company_admin": true, "manage_invites": true, "manage_team": true, "view_kitchen_reports": true}'::jsonb,
    team_join_seen = true,
    in_team = true
    where id = auth.uid();
  update kitchen_invites set revoked = true where id = p_invite;
  return true;
end;
$$;
