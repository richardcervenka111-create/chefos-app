# SUPABASE_CONSOLIDATION_PLAN.md

**Author:** Claude (Senior Database Architect pass), 2026-07-19
**Scope:** analysis + roadmap only. No SQL has been executed; `app/index.html` is unchanged.
**Baseline (measured, not estimated):** 49 tables, 156 migration files, 12 RPCs, 2 edge
functions. Every number below comes from scanning `app/index.html` for real `sb.from('…')`
call sites and `db/*.sql` for `create table` — rerun the scan before executing any phase,
the app moves fast.

---

## 1. What the frontend actually uses (measured)

Call-site counts per table in `app/index.html` (a call site ≠ request volume, but it maps
which features depend on which tables):

| Tier | Tables (app call sites) |
|---|---|
| **Hot core** | profiles (46), ingredients (19), prep_items (14), time_entries (12), prep_dishes (12), kitchens (11), recipes (11), order_list_items (9), tasks (8) |
| **Active features** | kitchen_invites (7), ingredient_lists (7), schedule_forecast (7), working_time_day_notes (7), access_requests (6), recipe_comments (6), haccp_checklist_items (5), email_contacts (5), print_label_log (5), recipe_category_icons (5), projects (5), recipe_shares (5) |
| **Light** | events (4), fridges (4), chef_connections (4), station_icons (4), user_settings (4), staff_members (4), check_list_audit_log (4), print_label_settings (4), favorites (3), app_config (3), custom_ingredients (3), recipe_lists (3), ingredient_price_history (3), schedule_assignments (3) |
| **Very light** | fridge_logs (2), haccp_checklist_log (2), haccp_measurement_log (2), shift_codes (2), recipe_notes (2), usage_events (2), privacy_acceptances (2), confidentiality_acceptances (2), feedback_reports (2) |
| **One call** | ai_usage (1), error_logs (1) |
| **DEAD — zero app calls** | `feedback` (empty leftover, superseded by feedback_reports per db/108), `profile_private` (draft db/69, never wired), `schedule_entries` (schedule v1, superseded by v2 in db/18) |

Mapping to Richard's three pillars: **KDS/Check List** = projects, prep_dishes, prep_items,
tasks (+ audit log); **kitchen journal** = HACCP tables, fridge logs, time_entries, day notes;
**inventory** = ingredients (+ lists, price history, order_list_items).

---

## 2. Honest architect's note before we cut

49 tables is **not a performance problem** for Postgres — the real cost is cognitive: more RLS
policies to audit (every table needs them), more migration surface, more places for the
personal/company-context class of bug. So the goal is **fewer moving parts**, not speed.
Consolidation only pays off if each step is small and shipped with its app change in the same
commit — a big-bang restructure of a live production DB with real pilot data is how data gets
lost. Everything below follows `db/README.md` (numbered migrations, STAGING FIRST for anything
touching data/constraints, `-- DESTRUCTIVE:` + Richard's explicit approval for drops).

---

## 3. Target schema (~24 tables)

### Keep as-is — the core 16
`kitchens`, `profiles`, `recipes`, `ingredients`, `prep_dishes`, `prep_items`, `tasks`,
`projects`, `order_list_items`, `events`, `time_entries`, `app_config`, `access_requests`,
`kitchen_invites`, `chef_connections`, `recipe_comments`

### Consolidations (33 tables → ~8)

| # | Today | Becomes | How |
|---|---|---|---|
| C1 | `feedback`, `profile_private`, `schedule_entries` | **dropped** | Dead: 0 app call sites each. Verify row counts in prod first; archive to CSV if non-empty. |
| C2 | `station_icons`, `recipe_category_icons` | `kitchens.icons` **JSONB** | Pure lookups (name→emoji). `{"stations": {"Hot Line":"🔥"}, "recipe_categories": {...}}`. Simplifies the frontend: one read at load instead of two queries. |
| C3 | `privacy_acceptances`, `confidentiality_acceptances` | one `consents` table | Same shape (user, version, accepted_at) + `kind` CHECK ('privacy','confidentiality'). Keeps the append-only legal audit trail (do NOT collapse to a profile flag — "what text did they agree to and when" must survive). |
| C4 | `print_label_settings` | `user_settings.settings` **JSONB** | user_settings gains a JSONB column absorbing per-user misc settings; `favorites` (recipe ids per user) and future toggles land here too → `favorites` table dropped. |
| C5 | `custom_ingredients` | `ingredients` | Same entity; add `source` text ('library','custom_upload','invoice_scan','order_adhoc'). The Custom Ingredients screen filters on it. |
| C6 | `recipe_notes` | `recipe_comments.kind` | 'comment' \| 'private_note' CHECK; RLS: private notes visible to author only. |
| C7 | `recipe_lists`, `ingredient_lists` | one `lists` table | Identical shape (name, icon, kitchen, creator, shared); `kind` CHECK ('recipe','ingredient'). `recipes.list_id` / `ingredients.list_id` both point here. |
| C8 | `haccp_checklist_log`, `haccp_measurement_log`, `fridge_logs` | one `haccp_log` | One journal: `kind` CHECK ('checklist','measurement','fridge_temp'), `item_id` nullable, `value_numeric`, `status`, `note`, `details` JSONB (fridge_id etc.). `haccp_checklist_items` stays (it's a definition table, not a log). `fridges` (names of fridges) → `kitchens.icons`-style JSONB or stays as tiny table — decide at execution. |
| C9 | `schedule_assignments`, `schedule_forecast`, `shift_codes`, `working_time_day_notes` | `staff_members` + one `schedule_days` | Per-(kitchen, date) grain unification: assignments, forecast numbers, and day notes are all keyed by date. `shift_codes` (code→hours lookup) → JSONB on kitchens. |
| C10 | `error_logs`, `usage_events` | one `app_events` | `kind` CHECK ('error','usage'), `details` JSONB. `ai_usage` stays separate — it's money/billing, different retention needs. |

### Stays separate deliberately
`check_list_audit_log` (the "who checked this off" product promise), `print_label_log` (Label
Expiry reads it structurally), `ingredient_price_history` (price-movement charts),
`feedback_reports`, `recipe_shares` (per-friend RLS is cleaner as rows than JSONB policies),
`email_contacts`, `ai_usage`, `haccp_checklist_items`, `staff_members`, `user_settings`, `lists`,
`consents`, `haccp_log`, `schedule_days`, `app_events`.

**Result: 16 core + 8 consolidated/kept-support = ~24 tables** (from 49). A further squeeze to
~20 is possible later (fold check_list_audit_log + print_label_log into app_events; consents →
profiles JSONB; tasks → prep_items) but each of those trades away a working feature's clean
query path — not recommended until the trial proves which features live.

### Anti-bloat rules going forward (also in CLAUDE.md)
- New feature ⇒ first ask: column on an existing table? JSONB? CHECK-constrained text? A new
  table is the last resort and must carry kitchen_id + RLS + the personal/company question.
- No lookup tables for static maps — JSONB on `kitchens` or constants in the app.
- Every log-shaped need goes to `app_events` unless it powers a structural screen.

---

## 4. Safe migration roadmap (expand → migrate → contract)

**Golden rules for every step:** one consolidation = one numbered migration + the matching
`app/index.html` change **in the same commit**; STAGING FIRST always (this whole plan is
data-touching by definition); `audit_app.py` ghost-table check must pass (it already fails the
commit if the app references a dropped table); old tables are **renamed to `zz_retired_*` for
one week before DROP** — instant rollback is a rename away; `-- DESTRUCTIVE:` + Richard's
explicit approval on every drop; verify row counts before/after each copy
(`select count(*)` old vs new must match).

**Phase 0 — prep (no risk):** re-run the usage scan; snapshot prod row counts for all 49
tables; full backup export.

**Phase 1 — dead weight (lowest risk, do first):** C1. Confirm 0 rows (or archive), rename to
`zz_retired_*`, drop a week later. 49 → 46. No app change needed (zero call sites — the
auditor's ghost-table check keeps it that way).

**Phase 2 — lookups & settings (low risk):** C2, C3, C4, C5. Pattern per step: add new
column/table → copy data (`insert … select`) → flip the app reads/writes → verify live on a
real phone → retire old table. 46 → 39.

**Phase 3 — same-shape merges (medium risk):** C6, C7, C10. `lists` is the one needing care:
`recipes.list_id`/`ingredients.list_id` FKs re-point; do it behind a compatibility view named
`recipe_lists` for one release if needed. 39 → 34.

**Phase 4 — journal unification (medium-high risk, needs Richard's live HACCP test):** C8,
then C9. These change RLS surface → run `scripts/tenant_isolation_test.sql` on staging after
each. 34 → ~24.

**Sequencing:** Phases 1–2 are safe **before** the 1.8. public trial. Phases 3–4 belong
**after** the trial starts and proves stable — restructuring the schedule/HACCP journals days
before letting 25 strangers in is risk with no user-visible payoff.

**Definition of done per phase:** audits green, staging tenant-isolation test green, Richard's
phone test green, row counts reconciled, old tables retired ≥1 week then dropped, CLAUDE.md
table count updated.
