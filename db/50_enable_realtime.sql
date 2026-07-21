-- Sautero — turn on Realtime for Check List's live cross-device sync (2026-07-13).
--
-- MVP_DEFINITION.md promises "updates visible to everyone in real time" for Check List — this
-- was never actually true until now; every screen only loaded data once per visit. The app
-- side (app/index.html: subscribeToRealtimeUpdates()) now subscribes to live change events on
-- these two tables, but Supabase only pushes events for tables explicitly added to the
-- `supabase_realtime` publication — this migration does that.
--
-- If you get an error like "relation is already member of publication" when running this,
-- that's fine — it just means Realtime was already on for that table. Nothing else to do.

alter publication supabase_realtime add table prep_items;
alter publication supabase_realtime add table prep_dishes;
