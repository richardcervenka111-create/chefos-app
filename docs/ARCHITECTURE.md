# Sautero — Architecture Direction

*Living document. This describes the SHAPE of the system in plain language, not implementation
detail. Updated as decisions get made — nothing here is code yet.*

## The kitchen analogy for the whole system

Right now, `Recipe_Book_v2.html` is like one cook's personal notebook — great for one person,
useless if the person at the next station needs to read it. Kitchen Flow needs an **expo
board**: one shared, always-current board that every station's phone/tablet reads from and
writes to, live, during service.

To build a shared expo board, we need three things a personal notebook doesn't:

1. **A pass** — a server that every device talks to, so a change made at the grill station
   shows up instantly on the pastry tablet. (Today's prototype has no pass — it's a single
   notebook with no way for anyone else to see it live.)
2. **A walk-in** — a real, shared database that stores recipes, prep boards, and users
   permanently and safely, not just in one browser's memory.
3. **A door with name badges** — accounts and roles (Chef, Sous Chef, Commis, etc.), so the
   board knows who's allowed to mark a task done vs. just view it.

## Recommended technical shape (for a solo builder + AI)

Because Richard is building this solo with AI assistance, the right choice is **not** to build
a server from scratch (that's like building your own walk-in fridge from raw sheet metal when
you could rent a commercial kitchen with one already installed). Instead:

- **Use a managed backend platform** (a "backend-as-a-service" — think of it as a commercial
  kitchen you rent that already has the walk-in, the pass, and the door badges installed, so
  you focus on the menu, not the plumbing). This handles accounts/login, the shared live
  database, and real-time updates, without needing a dedicated backend engineer.
- **Build the app as a mobile/tablet-first responsive web app**, installable to a home screen
  like a native app (a "PWA"). This means the pilot kitchen can start using it on tablets
  immediately, with no App Store review cycle slowing down iteration. Native mobile/desktop
  apps come later (Phase 6), once the product is proven and worth the extra build cost.
- **Move off `window.storage`.** The current prototype's save/sync system only works inside the
  specific tool that generated it — it will not work on a real tablet in a real kitchen. Phase 1
  replaces it with the real shared backend described above. This is expected and fine — the
  prototype's job was to prove out the UI and the ingredient-scaling logic, both of which
  carry forward.

## What carries forward from the existing prototype

- The visual design language (dark "kitchen notebook" theme, Apple/Notion-inspired layout)
- The recipe list/detail/edit UX
- The ingredient-based scaling logic (`applyIngredientScale` / `applyYieldScale`) — this is a
  real, working implementation of a feature explicitly required in the vision doc; we evolve
  it, we don't rebuild it from zero
- The standardized recipe data shape (title, category, sections, meta) — extended in Phase 1 to
  cover the full field list (Equipment, Chef Notes, Storage, Shelf Life, etc.)

## What does NOT carry forward as-is

- `window.storage` as the persistence layer (replaced by the real shared backend)
- Single-file structure (a real, multi-user product needs a proper project structure — this
  becomes a Phase 1 task, done carefully so nothing is lost)

## Backend platform recommendation (Phase 1 kickoff, 2026-07-08)

**Confirmed 2026-07-08: Supabase.**

Why: recipe data is deeply relational — a recipe has many ingredients, references other
recipes, belongs to a station and a kitchen, is edited by users with roles. That's the same
shape as a walk-in fridge with labeled shelves and a clear "this goes with that" logic — a
relational database (Supabase is built on Postgres, a well-established relational database)
fits that better than a loose, shelf-less storage bin (a "NoSQL" database like Firebase, the
main alternative). Supabase also bundles the three things `ARCHITECTURE.md` calls for above —
the pass (realtime updates), the walk-in (the database), and the door badges (accounts + a
permissions system that maps naturally onto Chef/Sous Chef/Commis roles) — in one rented
kitchen, with a generous free tier suitable for building and piloting before any revenue exists.

Alternative considered: Firebase (Google) — also solid, but its data model fits loosely
structured data better than the highly relational recipe/station/role structure Sautero needs.

## Open architecture decisions for Phase 2+ (not yet made)

- Exact roles/permissions model (who can edit vs. just mark tasks done)
- How the standardized recipe format is validated so imported/scanned recipes can't skip
  required fields
