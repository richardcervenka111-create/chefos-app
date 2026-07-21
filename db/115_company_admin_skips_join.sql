-- Sautero — accepting an Add Company invite also marks team onboarding as done (Richard,
-- 16.7. večer, bod 3): the new company admin already HAS their team, so switching their
-- account to Company must go straight in — never the "scan QR / enter code" join screen.
-- (The app also guards on company_admin client-side; this keeps the flag truthful in the DB.)

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
    where id = p_invite and grants_company_admin and not revoked and expires_at > now();
  if v_invite is null then
    return false;
  end if;
  if not exists (select 1 from profiles where id = auth.uid() and kitchen_id = v_invite.kitchen_id) then
    return false;
  end if;
  update profiles set
    admin_perms = coalesce(admin_perms, '{}'::jsonb)
      || '{"company_admin": true, "manage_invites": true, "manage_team": true, "view_kitchen_reports": true}'::jsonb,
    team_join_seen = true
    where id = auth.uid();
  update kitchen_invites set revoked = true where id = p_invite;
  return true;
end;
$$;
