-- 140: one-off repair — victims of the dual-purpose Add Friend QR (Richard, 17.7. PRIORITA).
--
-- Pre-17.7. personal "Add Friend" QRs carried BOTH ?invite= and ?friend= (db/95 era). Anyone
-- opening such a link joined the inviter's kitchen instead of just becoming a friend — that is
-- how 3 real people (Paula, Filip, Marc — Marc as late as 17.7. via a still-active old link)
-- ended up as members of Richard's My Kitchen, and why 3 others were stuck with NO kitchen at
-- all. None of the 6 had created any recipes (verified before running), so the move is safe.
--
-- APPLIED LIVE 17.7.2026 ~16:05 via the dashboard. Verified after: My Kitchen members = 2
-- (Head Admin + old founder test account), no_kitchen = 0, active My Kitchen invites = 0,
-- Richard's chef_connections = 7.
--
-- The permanent fix is app-side (same day): renderTeamGate() routes ANY URL carrying ?friend
-- to the friend-only path (own kitchen via ensure_personal_kitchen + chef_connections), even
-- when ?invite is also present; joinKitchenViaLink() carries the same guard as belt-and-braces.
-- Add Friend QRs themselves have been ?friend-only since the morning of 17.7.

update kitchen_invites set revoked = true
 where kitchen_id = '11111111-1111-4111-8111-111111111111' and not revoked;

do $repair$
declare
  rec record;
  new_kid uuid;
  rich uuid := (select id from profiles where email = 'richard.cervenka@icloud.com');
begin
  for rec in
    select p.id, coalesce(nullif(p.full_name,''), split_part(p.email,'@',1)) as nm
    from profiles p
    where p.email in ('paulapanizzon@gmail.com','hylfilip@gmail.com','marc_labuguen@hotmail.com',
                      'patriklachky@gmail.com','annychernysheva@gmail.com','sergey.paikov@icloud.com')
  loop
    insert into kitchens (name) values (rec.nm || '''s Kitchen') returning id into new_kid;
    update profiles set kitchen_id = new_kid, in_team = false where id = rec.id;
    begin
      insert into chef_connections (user_a, user_b) values (rec.id, rich);
    exception when unique_violation then null;
    end;
  end loop;
end $repair$;
