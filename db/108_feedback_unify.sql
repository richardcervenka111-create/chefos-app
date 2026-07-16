-- ChefOS — feedback unification (Richard, 16.7.: "feedback nefunguje odoslať").
--
-- Root cause of the broken sending was app-side, not SQL: yesterday's new Send Feedback
-- overlay (db/98) reused the element ids the OLD global feedback button (💬, db/61) already
-- owned, so each system silently read the other's hidden input. Fixed by deleting the
-- duplicate overlay — everything now goes through the original, richer system
-- (feedback_reports: feedback/bug/question types + screen context).
--
-- What SQL still needs: feedback_reports (db/61) only ever had an INSERT policy — nobody,
-- including Richard, could read it from the app at all (he was reading it via the SQL editor).
-- The Admin → Feedback inbox now points at feedback_reports, so Head Admin needs a real read
-- policy. db/98's `feedback` table stays as a harmless empty leftover (dropping tables in a
-- same-day migration isn't worth the risk; nothing writes to it anymore).

create policy "head admin reads all feedback reports" on feedback_reports
  for select using (is_super_admin());
