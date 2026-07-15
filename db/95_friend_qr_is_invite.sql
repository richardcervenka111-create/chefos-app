-- ChefOS -- personal "Add Friend" QR also works as a kitchen invite, for every member, not
-- just admins (Richard, 16.7., explicit call after a direct trade-off question: "každý pozýva
-- cez QR" -- every member's own QR invites, deliberately relaxing the admin-only restriction
-- db/81 put in place that same day).
--
-- This is a conscious, confirmed reversal of part of db/81 -- not a regression. What stays
-- unchanged from db/81: kitchen_invites tokens are still real (revocable, expiring, never a
-- bare kitchen id), and REVOKING one is still admin/manage_invites-only (see db/86) -- a
-- regular member's QR can create/reuse the kitchen's active invite, but can't take it away from
-- anyone. The self-serve "create your own kitchen" restriction (richard.cervenka@icloud.com
-- only) is completely untouched -- this is only about who can hand an EXISTING kitchen's door
-- key to someone else, not about minting new kitchens.
--
-- Safe straight to production: widens an INSERT policy only, no data changes.

drop policy if exists "create kitchen invite" on kitchen_invites;
create policy "create kitchen invite" on kitchen_invites
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
