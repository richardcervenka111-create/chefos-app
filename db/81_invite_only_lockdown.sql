-- Sautero -- Invite-only lockdown (Richard, 15.7. late night, bod 5): "nikto okrem
-- richard.cervenka@icloud.com sa dnu nedostane, iba ja môžem vytvárať invitation QR kódy
-- alebo posielať linky."
--
-- STAGING FIRST -- this tightens a live RLS policy (same class as db/62/db/80's lesson:
-- verify on staging before production).
--
-- Two real gaps this closes:
-- 1) "create kitchen invite" (db/53) only checked kitchen membership, not admin -- ANY team
--    member could mint a fresh invite QR/link for their kitchen, not just the admin.
-- 2) Same gap on revoking an invite.
-- Since db/80 already restricts is_admin to richard.cervenka@icloud.com only (until Richard
-- personally approves someone else), gating invite creation on is_admin achieves the "only I
-- can create invites" requirement at the database level, not just hidden in the UI (app-side
-- self-serve-kitchen-creation removal is the same commit, in app/index.html).
--
-- The admin-approval-request notification bod 5 also asked for ALREADY EXISTS (access_requests
-- table + notify-access-request edge function, built 15.7. earlier) -- nothing new needed there
-- except confirming the function is actually deployed (Richard: same manual step claude-proxy
-- needed -- run `supabase functions deploy notify-access-request` if you haven't already).

drop policy if exists "create kitchen invite" on kitchen_invites;
create policy "admin creates kitchen invite" on kitchen_invites
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid() and is_admin)
  );

drop policy if exists "revoke own kitchen invite" on kitchen_invites;
create policy "admin revokes kitchen invite" on kitchen_invites
  for update using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid() and is_admin)
  );

-- "read any invite" policy is untouched on purpose -- someone who isn't a member yet still
-- needs to read the invite row to know which kitchen they're about to join.
