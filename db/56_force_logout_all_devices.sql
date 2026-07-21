-- Sautero — force every device to log out and require a fresh email code (run on demand).
--
-- This is not a schema change — it's a one-off action, safe to run again anytime the same
-- way. It deletes every active session (Supabase Auth cascades this to the matching refresh
-- tokens), so no device can silently refresh its way back in.
--
-- Caveat: a device's CURRENT access token stays valid until it naturally expires (project
-- default is 1 hour) even after this runs — deleting the session stops it from being
-- *renewed*, it doesn't retroactively invalidate a token that's still live. For an immediate
-- kick (not just "next refresh"), also do this in the dashboard: Authentication -> Users ->
-- select all -> "Sign out" (or lower the JWT expiry under Authentication -> Settings, run
-- this, then set it back).
--
-- This logs YOU out too, on every device — including the one you run this from once its
-- token expires. Have your email ready to grab the next code.

delete from auth.sessions;
