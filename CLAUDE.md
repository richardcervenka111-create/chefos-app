# Sautero - Project Guidelines

## Project Architecture
- **Frontend:** Buildless single-file application located exclusively in `app/index.html`.
  Hand-written CSS (custom design system, navy/teal `#0A1A2F`/`#34F7D7`) and plain JavaScript —
  **no Tailwind, no framework, no build step**. The only external dependency is the Supabase
  client from CDN; a QR-code generator is vendored inline.
- **Backend/Database:** Supabase (project `azkhyorqnwvaugaomjvh`, staging `qavrkkgcgqgtrlrmqyfe`),
  connecting directly from the frontend under RLS. Server-side AI calls go through the
  `claude-proxy` edge function — the API key never ships to the client.
- **Docs:** `visual data/` holds the editable source documents; `scripts/build_docs.py`
  generates the 5 merged tabbed shells (produkt/plan/biznis/znacka/poznamky). Edit sources,
  never the generated shells.

## Critical Architecture Constraints (Anti-Bloat Rule)
- **Database Scope:** the schema currently has **49 tables across 156 migration files** (exact
  live numbers come from `python3 scripts/audit_db.py` — never quote table counts from memory).
  Richard's standing direction: keep the schema lean and **consolidate gradually toward a
  tighter MVP core** — do not add new tables when an existing one, a column, or an ENUM/text
  field can carry the feature.
- **No Over-Normalization:** avoid creating separate Supabase tables for simple statuses or
  static lookups. Use ENUMs or text fields instead.
- **Consolidation is destructive work:** merging/dropping live tables follows `db/README.md`
  rules (numbered migration, STAGING FIRST, `-- DESTRUCTIVE:` comment, Richard's explicit
  approval per statement). Never consolidate opportunistically inside an unrelated change.

## HTML & Layout Integrity Rules (Single-File Rules)
- **Component Isolation:** since the entire app lives in `app/index.html`, global layout
  structures (top bars, floating nav, overlays) must stay strictly separated from the dynamic
  view sections (`ALL_VIEW_IDS`).
- **No UI Duplication:** when fixing or adding features inside a specific view or document tab,
  NEVER duplicate or re-paste global navbar/header HTML. (Real incident 19.7.: anchor links
  inside srcdoc iframes resolved to the parent shell and recursively stacked the doc banner —
  `patchInnerLinks` in `build_docs.py` is the permanent guard. Bare `#anchor` links inside
  embedded docs are landmines.)
- **DOM Safety:** any DOM manipulation or view-swapping logic strictly modifies the inner
  content of the target container without breaking the outer layout skeleton.

## Technical Execution
- Always review the surrounding structure of `app/index.html` before modifying it to prevent
  code injection, missing closing tags, or duplicate rendering bugs.
- After every change: `python3 scripts/audit_app.py` (and `audit_db.py` when db/ is touched)
  must pass; the pre-commit hook enforces both plus `build_docs.py` freshness.
- Every app/db change is committed AND pushed (`git push origin main`) — local edits never
  reach app.sautero.ch.
- Every feature writing kitchen-scoped rows must separate personal vs company context
  (`is_personal`) — a team member's `kitchen_id` points at the company kitchen even in
  personal mode.

## Engineering Standard (permanent, 22.7.2026)
- **`docs/ENGINEERING_STANDARD.md` is binding for every change.** In short: the deploy gate
  runs the FULL lock suite against the candidate build on localhost BEFORE production — never
  bypass it; one module in development (`locked_tiles.json → in_development`), everything else
  enforced; significant new features ship dark behind `featureEnabled()` flags; "Done" modules
  immediately get a live-verified lock suite (`tile_lock_test.py`) and a `locked` entry;
  rollback = the "⏪ Rollback production" action. Never green a red test by weakening it —
  fix the root cause and state whether the app or the test was wrong.
