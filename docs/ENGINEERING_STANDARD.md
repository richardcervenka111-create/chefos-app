# Sautero Engineering Standard

**Adopted 22 Jul 2026 (Richard Červenka). This is the permanent development standard — every
change to Sautero follows it. The goal: a self-defending application. Every completed feature
protects itself automatically; regressions are caught BEFORE deployment, never after.**

---

## 1. Deploy Gate — nothing broken ever ships

Every push to `main` runs `.github/workflows/deploy-pages.yml`. Its `checks` job is the gate:

1. `pyflakes` lint → `audit_db.py` → `audit_app.py` → `calc_unit_test.js` (money math)
2. **LOCK GATE**: the candidate build (the app exactly as in the commit) is served on
   `localhost:8080` inside CI, and the **entire lock suite** (`tile_lock_test.py`) runs against
   it with the QA accounts — against the *new* code, before production sees anything.

If **any** locked module fails: the deploy stops, production stays untouched, and the failing
module + exact assertion appear in the GitHub job summary ("Tile locks" section). There is no
bypass. `workflow_dispatch` runs pass through the same gate.

The post-deploy `tile-locks.yml` run (after every deploy + 2×/day) is *drift detection* —
it catches environment/Supabase-side changes. The pre-deploy gate is what keeps regressions out.

## 2. Lock suites — one per stable module

A **lock suite** is a `check_<module>` function in `scripts/tile_lock_test.py`, registered in
`CHECKS` and listed in `scripts/locked_tiles.json → locked`. Each suite verifies, end to end on
a real browser with a real QA account:

- the module opens correctly and its critical UI elements exist
- its critical user flows work (real actions, real assertions on outcomes)
- data is genuinely stored (read back from the DB, row-count-verified deletes for cleanup)
- expected business behaviour holds (e.g. a check-out stores the *right* duration)
- no uncaught JS errors and no 5xx responses occur during the whole check

Suites are isolated: each runs in a fresh browser context; one failing suite names exactly the
module that broke. Suites clean up every row they create.

**Currently locked:** `working_time` (22.7.2026).

## 3. Development workflow — one module open, everything else locked

When actively developing ONE module, only that module may change. Put its key into
`locked_tiles.json → in_development` (if it was locked): its suite still runs and reports, but
failures are **waived** (its behaviour is legitimately in flux). Every other locked module stays
fully enforced — an accidental regression anywhere else **blocks the deploy**.

When the work is declared done: empty `in_development`, update the suite to the new intended
behaviour, live-verify, and the module is fully locked again.

## 4. Feature flags — unfinished work is invisible

Every significant new feature ships **dark** behind `featureEnabled('flag_name')`
(app/index.html, next to `demoModeAllowed`). A flag registered `{ enabled: false }` is visible
only to the internal QA/test accounts (`FEATURE_FLAG_INTERNAL_ACCOUNTS`). Release = flip
`enabled: true` after Richard approves on his phone. Deleting a flag entry is always safe
(unknown flags read as released). Production users never meet unfinished work.

## 5. Rollback — one click, ~3 minutes

Actions → **"⏪ Rollback production"** → Run workflow. Default target: the commit of the
*previous* successful deploy; or paste an explicit SHA. Frontend-only by design — git history
and the database are untouched (migrations are additive and versioned separately in `db/`).
The job summary states exactly which commit production now runs. Edge cache: ~10 min or `?v=`.

## 6. Continuous protection — "Done" ⇒ locked

The standing pipeline whenever Richard declares a module done:

1. Write its lock suite (`check_<module>`) covering the behaviours from its `test_sweep` items.
2. **Live-verify the suite** before committing (a broken lock test produces false alarms that
   erode trust in the whole board — never skip this).
3. Add the key to `locked_tiles.json → locked`.
4. From that moment it is enforced automatically: pre-deploy gate + post-deploy drift run +
   2×/day schedule. No further registration needed.

The protected surface only grows. End state: every production feature is locked.

## 7. Testing philosophy — fix causes, not symptoms

Never make a red run green by increasing timeouts, adding retries, disabling a test, or
weakening an assertion. Investigate the root cause; fix the app if the app is wrong, fix the
test if the test is wrong — and say which it was. (Precedents: the tutorial-overlay false
failure was fixed by muting tutorials — a real test defect; the tenant-test "leak" was the
intentional Public shelf — a real calibration, documented in the test.)

Two hard incident rules already encoded elsewhere and honoured here:
- privileged writes verify row counts (`.select()` + length) — silent no-ops are bugs;
- automated text rewrites anchor on exact element/attribute contexts, never bare phrases.

## 8. Future architecture — designed to extend, not rewrite

The pieces map forward without redesign:
- **Multiple developers / parallel work** → `in_development` becomes per-branch; lock gate runs
  per PR (the workflow already runs on any push — add `pull_request` when branches arrive).
- **Preview environments** → the localhost candidate-serve step *is* a preview; per-PR Pages
  previews slot into the same gate.
- **Staging** → point `--url` at a staging deployment + staging Supabase; the runner is
  URL-agnostic by design.
- **Canary / blue-green** → the rollback workflow already deploys an arbitrary SHA; canary =
  deploy SHA to a second Pages project + route a fraction; the lock suite is the promotion gate.
- **Scalable CI** → suites are isolated functions; parallelise via a matrix over `locked` keys
  when the suite count makes it worth it.

## 9. Documentation duties

- Every lock suite documents, in its docstring: the behaviours under lock, the lock date, and
  why each check exists.
- **Intentional behaviour change** in a locked module: change the suite in the SAME commit as
  the app change, note the old→new behaviour in the commit message, live-verify, keep the
  module out of `in_development` only if the suite already matches the new behaviour.
- This file is the onboarding document for any future developer. The QA layer map lives in
  `scripts/coverage_manifest.py` output; the daily health picture in `visual data/health.html`.

## 10. The standard in one sentence

**A feature is not done until it defends itself — and nothing that breaks a defended feature
can reach production.**
