-- Sautero — one-off fix (Richard, 16.7. večer): chefos@protonmail.com accepted the Add Company
-- invite (the kitchen move happened — the account is in the company's kitchen), but the
-- claim_company_admin grant silently didn't land, most likely because the single-use invite
-- was already consumed/revoked by an earlier open of the same link. This grants the exact
-- bundle the claim would have granted, plus the membership flags.

update profiles set
  admin_perms = coalesce(admin_perms, '{}'::jsonb)
    || '{"company_admin": true, "manage_invites": true, "manage_team": true, "view_kitchen_reports": true}'::jsonb,
  team_join_seen = true,
  in_team = true
where id = (select id from auth.users where email = 'chefos@protonmail.com');

-- Kontrola — vypíše stav účtu po oprave (má ukázať company_admin: true a meno kuchyne):
select p.admin_perms, p.in_team, p.account_type, k.name as kitchen_name
from profiles p
left join kitchens k on k.id = p.kitchen_id
where p.id = (select id from auth.users where email = 'chefos@protonmail.com');
