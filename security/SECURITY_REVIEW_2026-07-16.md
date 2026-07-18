# Sautero — Technical Security Review (self-review, 16 July 2026)

Written by Claude, not an independent auditor — treat this as a structured starting point for a
real security review, not a substitute for one. Ran `scripts/audit_db.py` against all 100
migrations first (tenant-scoping + RLS-presence + recursion checks) — clean.

## How access control works

Every table uses Postgres Row Level Security (RLS), scoped by `kitchen_id` — a user only ever
sees rows belonging to their own kitchen, enforced at the database layer (not just hidden in the
UI). A handful of `SECURITY DEFINER` functions exist for the few cases that need to cross that
boundary safely (e.g. looking up a kitchen by an invite code without exposing the whole table).

## What changed today (16 July) and why it should be safe

**Personal data isolation (`is_personal`, recipes + ingredients).** New RLS clause:
`(kitchen_id matches AND not is_personal) OR created_by = you`. A personal item is invisible to
everyone except its creator, at the database level, regardless of which kitchen they're
currently in — not just hidden by a UI filter (the old "Moje/Firemné" tabs *were* just a UI
filter; this closes that gap for anything created going forward).

**Team join codes.** The plaintext code is never stored — only its SHA-256 hash
(`kitchens.join_code_hash`). Lookup and joining both go through `SECURITY DEFINER` functions
(`lookup_team_by_code`, `join_team_by_code`) rather than a direct table SELECT, so the code
itself is never exposed via the broad `"read any kitchen name"` policy that already existed on
`kitchens` (db/34, predates today). Creating a team requires the new `create_teams` admin_perms
flag, checked explicitly inside the `SECURITY DEFINER` function (RLS itself is bypassed for a
function's own internal writes, so the check has to be explicit — it is).

**Kitchen Reports / employee hours.** `time_entries` previously had no admin-read policy at
all — only the owner could read their own entries. The new policy only grants a kitchen admin
read access to a specific employee's entries if that employee has separately set
`performance_tracking_consent = true`. No consent, no access, permanently, regardless of admin
permissions.

**Feedback.** Readable only via `is_super_admin()` — same function already used for the
profiles-lockout fix (db/90).

## Known gaps (flagging honestly, not fixed today — worth a decision)

1. **AI subscription gate is client-side only.** `callClaudeAPI()` in `app/index.html` refuses
   to call the AI proxy if a Personal account isn't subscribed — but the actual Supabase edge
   function (`claude-proxy`) doesn't independently re-check this. Someone who called the edge
   function directly (bypassing the app's JS) could currently use AI features without a
   subscription. Low real-world risk at pilot scale (small invited group), but this should move
   server-side before it's a real paywall.
2. **`kitchens` still has an open `"create kitchen"` INSERT policy from db/34** (any logged-in
   user can create a kitchen row directly, bypassing the new `create_team` RPC and its
   `create_teams` permission check). Today's work added a *more controlled* path alongside it,
   it didn't remove the old open one — unclear if anything currently depends on it. Worth a
   decision: keep both, or retire the old one now that `create_team` exists.
3. **Join codes have no attempt-throttling** beyond Supabase's general API limits. 6 uppercase
   alphanumeric characters (36^6 ≈ 2.2 billion combinations) is fine against casual guessing at
   current scale, but isn't a substitute for real rate-limiting if Sautero grows.
4. **Revoking hours-sharing consent is not retroactive** — it stops future admin reads, but
   doesn't (and can't) un-show data an admin already viewed in a past report. Normal limitation
   of this kind of feature, worth stating plainly to users rather than implying otherwise.
5. **No formal DPA on file** with Supabase or Anthropic yet (see README.md).

## Not touched today, still true from before

- Column-level `GRANT`/`REVOKE` history on `profiles` has been messy in the past (db/62 → 68
  emergency revert → several later migrations adding defensive per-column grants). Every new
  column added today follows the "always add a defensive grant" standing practice — no attempt
  was made to fully reconstruct or clean up the historical state, which remains somewhat
  uncertain.
- RLS-recursion is now a hard-fail check in `scripts/audit_db.py` (added after two real
  incidents, db/53 and db/86) — every policy written today was checked against that pattern by
  hand in addition to the script passing.
