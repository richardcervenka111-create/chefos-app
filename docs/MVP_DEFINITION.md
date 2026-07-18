# Sautero — MVP Definition (v1)

*Living document. Last updated: 2026-07-08 (end of Phase 0).*

## In one sentence

Sautero v1 is a mobile/tablet-first live prep board — **Kitchen Flow** — for one professional
kitchen, backed by a proper standardized recipe system, so a chef can see at a glance what's
done, in progress, waiting, or blocked at every station, without a single conversation about
whose fault it is.

## Who it's for

**Professional kitchens (Level 2 – Chef Pro solo, and Level 3 – Restaurant team).**
Not home cooks. Home cook recipe apps are a crowded, low-margin market and don't exercise the
one feature nobody else does well — Kitchen Flow only matters where there's a team and a
service to run.

## What v1 DOES include

- Standardized recipe format (per the full field list Richard defined) for every recipe
- Recipe calculator: scale by servings, by final yield, or by one reference ingredient
- Kitchen Flow live prep board: stations, tasks, four states (Waiting / In Progress / Done /
  Blocked), updates visible to everyone in real time
- Basic multi-user roles (Chef, Sous Chef, Chef de Partie, Commis, Manager) — enough to assign
  work and see who's on which station, without turning into a surveillance tool
- Runs as an installable mobile/tablet-first web app — works like an app on the line, no App
  Store approval needed to start piloting

## What v1 explicitly does NOT include yet (later phases)

- Inventory, food cost, shopping lists (Phase 3)
- Production planning, service planning, reports/analytics (Phase 4)
- AI forecasting / pattern-learning assistant (Phase 5 — needs real usage data first)
- Native mobile app, desktop app, offline mode, multi-location (Phase 6)
- Home Cook tier (Level 1) — deferred indefinitely, revisit only after Chef Pro/Restaurant is
  proven

## Why this scope

The full Sautero vision is a multi-year, 20+ feature platform. Trying to build all of it before
proving the core idea works in a real kitchen is the single biggest risk to the company. We
have a real pilot kitchen willing to test with real service — that's the most valuable asset
right now, and the fastest way to find out if Kitchen Flow actually reduces stress or just adds
another screen to check.

## Decisions locked in Phase 0 (2026-07-08)

| Decision | Choice | Reason |
|---|---|---|
| First customer | Professional kitchens (Chef Pro / Restaurant) | Real budget, real pain, needs Kitchen Flow |
| First platform | Mobile/tablet-first web app | Line cooks use phones/tablets during service, not laptops |
| Pilot kitchen | Confirmed — real kitchen available | De-risks design; real service reveals what a spec can't |
| Build team | Solo (Richard) + AI assistance | Architecture must stay simple enough for one non-developer to run |

See `ARCHITECTURE.md` for the technical shape and `ROADMAP.md` for phase-by-phase status.
