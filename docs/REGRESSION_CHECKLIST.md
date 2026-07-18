# ChefOS — Manual Regression Checklist

Run this by hand before any deployment that matters (definitely before the public trial, ideally
before any batch of changes goes live). Not automated — just a written list, because the single
biggest real risk this project has hit (the two script-order bugs on 2026-07-12) was exactly the
kind of thing this would have caught in two minutes instead of an "app is broken" report.

Check each box on a real device, not just by reading the code. ~15-20 minutes end to end.

## Login & team
- [ ] Log in with a fresh magic-link code
- [ ] Log out and back in — lands on Home, not the login screen or a blank page
- [ ] Open My Team — invite link + QR code both render, "Copy Link" works
- [ ] Open the invite link in a private/incognito window — shows the "You're invited" screen

## Recipes
- [ ] Recipes opens showing Favorites (or All, if nothing's favorited) — not a blank screen
- [ ] Open a recipe, scale the yield, confirm quantities update
- [ ] Edit a recipe, Save, reopen it — the edit stuck
- [ ] 🔍 Search & Filter — type a query, apply a diet filter, confirm results narrow correctly
- [ ] Add a new recipe manually, save, confirm it appears in the list
- [ ] ☰ category picker — switch categories, confirm the right recipes show

## Check List
- [ ] Open Check List — title shows, sticky header collapses on scroll
- [ ] Switch stations via ☰ — station switches, items load
- [ ] Check an item to a new status (TO DO → CHECK → FINISH) — status sticks after reload
- [ ] Log a prep time on an item's clock icon
- [ ] Add a new item to a dish, confirm it saves
- [ ] Open the "All" cross-station view — loads without error

## Ingredients
- [ ] Open Ingredients — topbar is compact, not eating half the screen
- [ ] 🔍 Search & Filter — the live match-count updates as you tap a filter chip
- [ ] Add a new ingredient, save, confirm it appears
- [ ] Open Ingredient Audit, confirm it runs without error

## Order List / Print Labels
- [ ] Order List — add an item, confirm it shows up grouped by section
- [ ] Print Labels — queue an item, tap Print, confirm the browser print dialog opens with a
      real 5×3cm label (not a blank page)

## Working Time
- [ ] Check in, log a break, check out — hours show correctly in the summary
- [ ] Open a day's detail and type a note — text is visible while typing (this exact bug shipped
      once already, on 2026-07-13 — don't let it regress silently)

## Cross-device sync (new as of 2026-07-13 — this is the one most likely to have a real bug)
- [ ] Two devices (or two browser tabs, one in incognito, logged in as different pilot users)
      open the same Check List station
- [ ] Change an item's status on device A — confirm it updates on device B within a few seconds,
      with no manual refresh

## AI features
- [ ] Chef's Assistant — send a message, get a reply (confirms the Supabase Edge Function proxy
      is actually deployed and working, not just present in the code)
- [ ] Photo-scan a recipe (or Language Audit, or any other AI feature) — confirms the same thing
      from a second call site

## General
- [ ] No JS errors in the browser console on any of the above (or check `error_logs` in Supabase
      afterward — should be empty for a clean run)
- [ ] Test on at least one device that isn't your own primary phone

## Parita Personal ↔ Company (doplnené 18.7.2026 — poučenie z chýbajúceho „New List")

Štrukturálne kontroly (auditory, error_logs, RLS) túto triedu chýb NIKDY nechytia — chýbajúce
tlačidlo nevyhodí chybu. Preto pri každom deep health checku a po každej zmene režimovej
logiky preklikať OBA režimy (ideálne protonmail účet) a porovnať:

- [ ] **Recipes home:** Personal = Moje + ChefOS + Public + projekty + Add Project;
      Company = ChefOS + Public + Company + projekty + Add Project (bez „My Recipes")
- [ ] **Ingredients home:** Personal = ChefOS + My Ingredients + Public + zoznamy + New List;
      Company = ChefOS + Public + zoznamy + New List (bez „My Ingredients")
- [ ] **Pravidlo parity:** čo sa dá vytvoriť v jednom module (projekt/zoznam/sekcia), musí sa
      dať vytvoriť v druhom module v ROVNAKÝCH režimoch — akákoľvek asymetria je bug
- [ ] HACCP: Personal skryté, Company viditeľné; Home dlaždice sedia s account_type
- [ ] Prepnúť režim tam a späť — police sa vrátia presne do pôvodného stavu
