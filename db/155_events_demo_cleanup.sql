-- 155: cleanup follow-up to db/153 (Richard, 18.7.: "demo event lieta v obrazovke a nieje pevne
-- uchytený... od teraz vždy budeme demo ilustrácie robiť takto" — same toggle-based illustration
-- pattern as Working Time's _wtDemoMode, never a real seeded row again). Deletes the one real
-- demo row that was written under the old (wrong) approach, then drops the now-dead is_demo
-- column — nothing writes it anymore, illustration events live only in memory client-side.
--
-- DESTRUCTIVE: deletes rows where is_demo = true (only ever the one seeded demo event, never
-- real bookings — is_demo was exclusively set by the seed function just removed) and drops a
-- column. Richard's own instruction this same turn is the approval.
--
-- Safe straight to production — the delete is scoped by is_demo = true (not a bare delete), and
-- the dropped column has no other reader/writer left in the app after this commit.

delete from events where is_demo = true;
alter table events drop column if exists is_demo;
