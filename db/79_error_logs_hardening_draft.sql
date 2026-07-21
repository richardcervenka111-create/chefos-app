-- Sautero -- error_logs hardening draft (health check 2026-07-15). STAGING FIRST.
--
-- Context: db/73 deliberately opened error_logs INSERT to anonymous users so pre-login
-- failures (the OTP-send path) can log themselves. Accepted trade-off at the time; the
-- health check re-reviewed it. Residual risk: an anonymous writer can insert arbitrarily
-- LARGE rows (volume abuse remains possible but is bounded by Supabase rate limits and
-- the table having no anon READ path -- nothing to exfiltrate).
--
-- This constraint caps row size so a single abusive client can't balloon storage.
-- Class: constraint change on a live table -> STAGING FIRST (it validates existing rows;
-- if any existing row exceeds the caps, trim it there first and re-run).

alter table error_logs
  add constraint error_logs_message_len check (char_length(message) <= 4000),
  add constraint error_logs_stack_len check (stack is null or char_length(stack) <= 8000);
