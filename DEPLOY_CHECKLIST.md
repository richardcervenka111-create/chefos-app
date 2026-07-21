# Sautero — Deploy checklist

Pushing `main` auto-deploys `app/` to production (app.sautero.ch) via GitHub Pages,
**gated by CI health checks** (`.github/workflows/deploy-pages.yml` — a failing auditor
blocks the deploy). The local pre-push hook prints this contract on every push to main.

## Before pushing app/index.html changes
- [ ] `python3 scripts/audit_app.py` passes (hook runs it automatically)
- [ ] If the change touches auth, saving, or deletion: test live on a real phone before
      telling anyone it works. A structural check is NOT a live test.

## Before running a new db/*.sql migration
- [ ] `python3 scripts/audit_db.py` passes
- [ ] Header states its class: "safe straight to production" (pure new table /
      function redefinition) vs "STAGING FIRST" (data/constraint changes)
- [ ] Staging-first class: run on `chefos-staging`, verify, only then production
- [ ] If it touches RLS policies: run `scripts/tenant_isolation_test.sql` on staging
- [ ] Destructive statements: Richard has explicitly approved the exact statement

## One-time per clone
- [ ] `sh scripts/setup_hooks.sh` (activates the committed git hooks)
