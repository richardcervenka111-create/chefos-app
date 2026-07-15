# ChefOS — Project Roadmap

*Living document — status updated as we complete each phase. We do not start a phase's tasks
until the previous phase is explicitly approved by Richard.*

> **Status sync 2026-07-15 (health check):** this table was frozen at 2026-07-08 while the
> project moved on — a code-vs-docs contradiction. Statuses below are now corrected. The
> LIVING status source is `visual data/status.html` (daily) — this file records phase
> definitions and decisions, not day-to-day progress.

| # | Phase | Status | Objective |
|---|---|---|---|
| 0 | Foundation & Validation | **Done 2026-07-08** | Define exactly what ChefOS v1 is, for whom, and on what technical foundation |
| 1 | Core Recipe Engine | **Done 2026-07-09** (1a data foundation + 1b AI import live) | Rebuild the recipe backbone (full standardized format, calculator, AI import) on real, shared infrastructure |
| 2 | Kitchen Flow MVP | **Largely built, not service-tested** — Check List live since 2026-07-09-10, roles/live-service validation pending | The live prep board, multi-user roles, tested in the real pilot kitchen |
| 3 | Inventory, Food Cost & Shopping | **Partially pulled forward** — priced ingredients (~1,300 live), food cost + yield, Order List; real stock tracking not started | Connect recipes to real stock levels and real cost numbers |
| 4 | Production Planning & Reports | Not started | Service planning, prep forecasting groundwork, basic analytics |
| 5 | Intelligence Layer | Not started (daily ingredient agent exists as a precursor) | Real AI recommendations, once there's real usage data to learn from |
| 6 | Platform Expansion | Not started | Native mobile + desktop apps, offline mode, multi-location support |
| 7 | Launch | Not started — public trial (25 users) targeted 2026-08-01 as its precursor | App Store / Play Store submission, pricing, onboarding, go-to-market |

## Phase 0 — Foundation & Validation (current)

**Objective:** Get an unambiguous, written definition of ChefOS v1 before writing new product
code.

**Decisions made 2026-07-08:** see `MVP_DEFINITION.md` for the full write-up.
- First customer: professional kitchens (Chef Pro / Restaurant), not home cooks
- First platform: mobile/tablet-first installable web app
- Pilot kitchen: confirmed available for real-service testing
- Build team: solo (Richard) + AI assistance

**Closed 2026-07-08** — Richard approved `MVP_DEFINITION.md` and `ARCHITECTURE.md` as written.

## Phase 1 — Core Recipe Engine (current)

**Objective:** Replace the prototype's local, single-browser storage with a real shared
backend, and expand the recipe format to the full standardized field list, so every later
phase (Kitchen Flow, food cost, AI) has solid ground to stand on.

**Reason:** Kitchen Flow (Phase 2) cannot be built on top of data that lives in one browser —
it needs a shared "walk-in" every device can read from. Doing this migration now, before
Kitchen Flow, avoids rebuilding it twice.

**Proposed sub-phasing (pending confirmation):**
- **Phase 1a — Data foundation + manual recipes:** set up the real backend, the full recipe
  data model (all fields from the original spec), migrate the existing ~173 prototype recipes,
  rebuild browse/search/detail/edit/scale on the new backend.
- **Phase 1b — AI Recipe Import:** photo → OCR → metric conversion → standardized format via a
  real AI call (the prototype only had the button; no AI was ever wired up).

**Tasks (Phase 1a):**
1. Stand up the backend project (recommended: Supabase — see `ARCHITECTURE.md` update below)
2. Design the recipe data model covering every field from the original spec: Name,
   Description, Yield, Prep Time, Cook Time, Ingredients, Equipment, Method, Chef Notes,
   Storage, Shelf Life, Variations, Scaling Notes, Difficulty, Cuisine, Station, Cost,
   Allergens, Tags, Cross References, Plating Suggestions
2. Design Kitchens/Users/Roles tables (structure only — Phase 2 turns roles into real
   permissions)
3. Migrate the ~173 existing recipes into the new data model
4. Rebuild list/search/detail/edit UI against the real backend (visual design carries over)
5. Port the ingredient/yield scaling calculator to the new data shape

**Tasks (Phase 1b, after 1a):**
6. Wire up a real AI call for photo → recipe (OCR + rewrite into standard format + metric
   conversion)
7. Decide how AI usage is paid for (Richard's own API key vs. built into a future
   subscription) — revisit at 1b kickoff, not blocking 1a

**Risks:**
- Recipe format has 20 fields; real recipes will rarely have all of them filled in — need a
  sensible "required vs optional" split so recipe entry doesn't feel like a tax form
- Migrating 173 recipes by hand would be slow — plan is a one-time scripted migration, not
  manual re-entry
- Scope creep risk if 1a and 1b are done as one block — sub-phasing avoids a single giant
  "nothing works until it's ALL done" stretch

**Deliverables (Phase 1a):** working recipe browse/search/detail/edit/scale, backed by a real
shared database, with all 173 existing recipes migrated and the full field list available.

**Confirmed by Richard 2026-07-08:**
- Backend: Supabase — approved
- Sub-phasing into 1a/1b — approved
- Migrate all ~173 existing recipes immediately in 1a (not starting fresh) — approved

**Status: core rebuild confirmed working end-to-end (2026-07-09).** Richard tested live: login
(email + code via Resend SMTP), recipe browsing, favorites (persist across refresh), notes,
scaling, and edit+save (persists correctly) all work against Supabase. Two real bugs found and
fixed during testing:
- Signup trigger failed ("Database error saving new user") — fixed by schema-qualifying table
  names in the trigger function (`db/03_fix_signup_trigger.sql`).
- Ingredient lines with two numbers at once (e.g. "1 pc → 130 g") only had the first number
  rescaled when scaling the recipe — fixed `scaleQtyString`/`parseLeadingNumber` in `app/index.html`
  to scale every number in the line, and to anchor "scale from one ingredient you have" on the
  weight/volume unit rather than a piece count (more reliable in a real kitchen).
Also confirmed: since all recipes are now editable (not just "custom" ones), Richard corrected
a wrong quantity in a migrated recipe himself via the edit button — this works as intended.

**Remaining for Phase 1a:** the database already has all 20 spec fields (equipment, chef notes,
storage, shelf life, variations, scaling notes, plating suggestions, cuisine, station, tags,
cross references, description, allergens) but the add/edit form only exposes title/category/
subtitle/ingredients/steps (same fields the old prototype had). Exposing the rest in the form —
without it feeling like a tax form — is the next task, pending Richard's go-ahead.

## Ingredients & Pricing (pulled forward from Phase 3, started 2026-07-09)

Richard asked to jump ahead to part of Phase 3 (Food Cost/Inventory) before finishing the rest
of Phase 1a — explicitly acknowledged as a sequencing choice, not silently done. Built:
- `ingredients` table (535 items, seeded from every ingredient used across the 173 recipes,
  tagged European/Asian/Universal, priced in EUR) — see `db/05_ingredients_schema.sql` and
  `db/06_ingredients_seed.sql`.
- New "Ingredients & Pricing" screen in `app/index.html` — browse/search/add/edit/delete.
- A best-effort cost-matching engine: recipe ingredient lines are matched to the ingredients
  table by name (with alias support), quantities are parsed and unit-converted (g/kg, ml/l),
  and an estimated recipe cost is shown in the recipe detail view with a "matched N of M
  ingredients" coverage note — deliberately transparent about being partial/approximate rather
  than presenting a guess as exact.

**Important caveat:** all 535 seed prices are `estimated` (reasoned from general culinary/
wholesale domain knowledge), not individually verified online — web search was rate-limited
for the entire session this was generated in, despite Richard asking for internet-researched
current prices. This should be revisited (either a fresh research pass, or Richard spot-checks
the ones that matter most) — flagged clearly to Richard, not silently presented as verified.

**Known limitations to revisit:** name-matching is exact-normalized-text only (no fuzzy
matching) — new recipes using different wording for the same ingredient won't auto-match
unless an alias is added; piece-priced ingredients (e.g. garlic priced per whole head) can't
be cost-matched against a recipe line written in grams (no reliable weight-per-piece data).

**Added 2026-07-09, same session:**
- Cost breakdown "i" button on the recipe detail's estimated-cost line — expands a per-ingredient
  line-item view (qty → converted amount → unit price → line cost).
- Editable "Production time" field per recipe (`db/07_production_time.sql`, separate from the
  existing active/passive method-time estimates) — will feed the upcoming Mise en Place feature.

## Mise en Place + ingredient substitutes — built 2026-07-09

Richard confirmed: Mise en Place is personal-only for now (not a shared team board — that
remains the bigger future "Kitchen Flow" step), tasks DO link to recipes (borrowing title/
production time), and ingredient origin/season/substitutes should be backfilled for all 535
existing ingredients right away (same approach as pricing).

**Built:**
- `tasks` table (`db/09_tasks_schema.sql`) — station, task text, priority 1-5 (1=critical),
  optional `recipe_id` link, production_time, done flag. Kitchen-scoped like recipes/ingredients
  so a future shared board doesn't need a schema change — the app just doesn't expose that view
  yet.
- "Mise en Place" screen in `app/index.html` — grouped by station, priority badges, tap to
  check off or edit, linking a recipe auto-fills production time.
- `ingredients` table gained `origin`, `season`, `substitutes` columns
  (`db/08_ingredient_substitutes.sql`).
- Ingredient info panel — an "i" button next to every ingredient line in a recipe's ingredient
  table opens a bottom sheet with origin/season/price/substitutes, matched via the same name+alias
  lookup the cost engine uses (same honest limitation: only works for lines that match something
  in the ingredient list).
## Batch of features — 2026-07-09 (same session)

- **Task status** (`db/11_task_status.sql`): tasks now have a 3-state status — TO DO → CHECK →
  FINISH — instead of a plain done checkbox. Tap the status badge in the list to cycle it, or
  set it directly in the edit form.
- **Recipe Active/Passive time + Station fields** exposed in the add/edit form (the DB columns
  already existed from Phase 1a's schema but had no UI until now).
- **Mise en Place "quick add from recipes"**: when a specific station chip is selected, a
  checklist of recipes tagged to that station appears — tap to select (turns red, more intense
  red at higher priority), adjust priority per item, selected items float to the top sorted by
  priority, "Add selected" bulk-creates tasks. Requires recipes to have their Station field set.
- **Ingredient ↔ recipe cross-linking**: when an ingredient line inside a recipe matches
  another recipe's title (e.g. "Sushi vinegar" inside "SPA" when a "Sushi Vinegar" recipe
  exists), it renders as a clickable link to that recipe, and `computeAllergens` now recurses
  into linked recipes so allergens hidden inside a sub-recipe surface on the recipe that uses
  it (with a visited-set guard against circular references).
- **Order List** (`db/12_order_list_schema.sql`, new "Order List" nav button): per-station
  checklist built from the full 535-item ingredient list, grouped by category — check an
  ingredient, set quantity + unit (kg/l/pc), Save. A row only exists in `order_list_items`
  while it's actually on that station's list (unchecking deletes it, save does a clean
  delete-then-reinsert for that station rather than a diff).

**Task rows redesigned:** each row now shows all three status options (TO DO / CHECK /
FINISH) as separate tap targets instead of one cycling badge (`db/11_task_status.sql`
unchanged, just the UI).

**Mise en Place simplified (replaced the manual "Quick add" screen):** opening a station tab
now auto-creates a TO DO task (priority 3) for every recipe tagged to that station that
doesn't already have one — the checklist is just there, row by row, no extra add step. A
column header (Task / Priority) appears above the rows when a specific station is selected.
Manually-added tasks (no linked recipe) are untouched by this. Removed the old
quick-add screen/state entirely rather than keeping two ways to do the same thing.

**Nutrition breakdown:** the "i" button pattern from cost is now also on the calories line —
expands a per-ingredient kcal/protein/carbs/fat breakdown, same transparency approach.

## Autonomous batch — 2026-07-09, later same session

Richard granted broad autonomy to proceed on well-scoped technical work without per-step
check-ins (see memory `feedback-chefos-autonomy-grant`). Completed in this batch:

- **Full 20-field recipe form.** All the Phase 1a spec fields that already existed as DB
  columns but had no UI (description, cuisine, equipment, chef notes, storage, shelf life,
  variations, scaling notes, plating suggestions, cross references, tags, yield) are now in
  the add/edit form, tucked into a collapsible "More details" section so the fast path
  (title/category/ingredients/method) stays quick. Shown in the recipe detail view too, only
  when filled in.
- **Mobile audit.** Added a global `overflow-x:hidden` safety net on `html,body`; fixed the
  cost/nutrition stat blocks to wrap into 2 columns instead of forcing 4 across; ingredient
  quantity column no longer forces `nowrap` (long compound quantities can wrap instead of
  pushing the page wider than the screen); generalized flex `min-width:0` so row text
  actually shrinks instead of overflowing.
- **Data quality pass.** Parsed the generated pricing/nutrition seed SQL and the migrated
  recipe quantities programmatically: no physically impossible macros (none >100g/100g), no
  zero/negative prices, no zero or absurd recipe quantities. A handful of kcal values looked
  inconsistent against a protein/carb/fat estimate (Sake, wine, vanilla extract) but that's
  explained by alcohol content contributing calories outside those three macros — not a bug.
  Nothing needed fixing.
- **Phase 1b — real photo-scan, done.** `db/15_user_settings.sql` adds a private
  (RLS-locked-to-owner) table for each person's own Anthropic API key. Rebuilt the add-choice
  sheet (Type it in / Scan a photo / Photo-scan settings) from the original prototype design.
  The key is typed directly into the app's own settings field by the user — never seen or
  handled by the assistant. Scanning calls Claude's Messages API directly from the browser
  (`anthropic-dangerous-direct-browser-access` header) with a forced tool-call
  (`record_recipe`) so the response is always structured JSON, not prose to parse — asks
  Claude to correct spelling, standardize terms, and convert to metric. Result lands in the
  normal add/edit form for review before saving, not auto-saved.

**New SQL to run (in order):** `15_user_settings.sql`.

## Mise en Place corrected — 2026-07-09, later still

Richard clarified real workflow: every evening he (or whoever's closing) writes tomorrow's
prep list from scratch — short lines like "cut cucumber," "portion steaks," "make salad
dressing" — for himself or the next shift. He explicitly categorizes this as Phase 4-adjacent
daily kitchen planning, not the recipe-linked/station-tagged system built earlier today, and
asked for it to be as close to zero-friction as possible.

Added a **Quick Daily List** mode: one big textarea, one task per line, a station picker, Save
— creates every task in one action. This is now the default FAB action in Mise en Place. The
detailed per-task form (priority, recipe link) is still there as a secondary path via a text
link, for when that's actually needed — not the default friction.

## App visual design elevated — 2026-07-09, later still

CSS-only pass (no HTML structure, IDs, or onclick handlers touched — every functional
reference verified intact afterward) bringing the working app's look up to the same bar as
the manifesto page: refined color tokens (slightly warmer copper/sage), a real focus-visible
state everywhere (was completely missing before — an accessibility gap), consistent hover/
active transitions on every interactive element, a properly designed login screen (card,
mark, tagline, entrance animation), a 3-up icon nav row replacing three stacked text buttons,
bigger/more confident type on recipe titles and section headings, and general spacing/
component polish (chips, FAB, buttons, cost blocks, form fields, empty states).

## Home dashboard + two new modules — 2026-07-09, later still

Richard asked for the recipe list to become one tile among peers, plus two new sections. Note:
he referenced a PDF of his actual work schedule format that never actually arrived in the
chat — built a reasonable sketch-level v1 instead, flagged clearly to him, pending the real
reference to refine against.

- **Home dashboard**: new landing screen after login, 6 icon tiles (Recipes, Ingredients,
  Mise en Place, Order List, Schedule, Fridge Temp). Recipes moved behind its own tile instead
  of being the default view; the 3 nav buttons that used to live in the recipe list's topbar
  are gone from there (now home tiles). Every other screen's "back" button now points Home
  instead of "All recipes" — except the recipe detail view, which still correctly goes back to
  the recipe list.
- **Schedule** (`db/16_schedule_schema.sql`): pick a date, see all 7 stations, type a name +
  Enter to add someone to that station for that day, tap × to remove. Plain text names, not
  linked to real user accounts — deliberately simple for v1.
- **Fridge Temperature** (`db/17_fridge_schema.sql`): name fridges/freezers with a target
  range, log a reading (manual entry), see at a glance (colored dot) whether the latest
  reading is in range, view recent history. No wireless sensor integration yet — there's no
  hardware to integrate with — but this is explicitly aimed at eventually replacing the
  "eCheck Pro"-type tool Richard finds impractical today.

**New SQL to run (in order):** `17_fridge_schema.sql` (in addition to the still-pending
`15_user_settings.sql` from the photo-scan feature, if not run yet). `16_schedule_schema.sql`
is now superseded — see below, skip it.

## Schedule rebuilt to match the real thing — 2026-07-09, later still

Richard sent the actual PDF this time: a 3-week "Dienstplan Küchenteam" export from Hotel
Schweizerhof Bern AG (his real employer). It's a genuine shift-code grid — staff × date, each
cell a code like `PJM`/`BKFST`/`FR` from a ~28-code legend with real hours and break windows —
not the simple "name per station per day" v1 built earlier blind. Rebuilt from scratch to
match:

- `db/18_schedule_v2_schema.sql` — drops the old `schedule_entries` table, creates
  `shift_codes` (code, label, start/end time, second start/end for split shifts, break note,
  is_absence flag), `staff_members` (name, section, active), `schedule_assignments`
  (staff × date, one row each, references a shift code + optional note).
- `db/19_schedule_v2_seed.sql` — seeds all 28 real shift codes (FE/FI/FK/FR/MI/MV/SC as
  absence codes with no hours; PJM/BKFST/JTD/etc. with their actual real start/end times and
  breaks, straight from the PDF's own legend) and all 27 real staff names from the roster,
  grouped into their real sections (Management, SKY, Bankett, Saucier, Entremetier,
  Gardemanger, Patisserie, Frühstück).
- App: week-view grid (staff rows grouped by section, 7 date columns, horizontally
  scrollable with a sticky name column), tap any cell to assign a shift code (grouped
  Absence/Shifts in the picker, shows the code's actual hours once selected) or add a note,
  prev/next week navigation, add/edit staff inline.

**Not seeded:** the actual day-by-day assignments from the PDF (which recipe/shift goes on
which specific day) — that 3-week snapshot will already be stale by the time this is used:
seeded the durable structure (who exists, what codes mean) and left the grid itself empty for
Richard to fill in going forward.

**New SQL to run:** `18_schedule_v2_schema.sql`, then `19_schedule_v2_seed.sql`.

**Mise en Place — SKY prep sheet (sketch).** Richard photographed his real paper prep sheet
for the SKY station (dish name + CHF price as a header, its ingredient/component rows
underneath). Added a general-purpose "prep sheet" style inside Mise en Place — any station
listed in `PREP_SHEET_STATIONS` (currently just `SKY`) gets this dish-grouped view instead of
the normal flat task checklist:

- `db/20_prep_sheet_schema.sql` — `prep_dishes` (station, name, price, sort order) and
  `prep_items` (dish_id, name, `on_hand` text, `priority` 1–5 int with 1=critical/5=can wait,
  `prep_time` free text), both kitchen-scoped with RLS, same pattern as every other table.
- `db/21_prep_sheet_seed.sql` — all 25 real SKY dishes and 69 real items transcribed from the
  photographed sheet.
- App: tapping the SKY chip in Mise en Place renders dish cards (name + price) with an
  editable table underneath — Item / On Hand / Priority (1–5) / Time to prep — each field
  autosaves on change, same as the existing task status buttons.

**Deliberately left as a sketch, not final:** "Time to prep" is a plain free-text field per
item for now. Richard's intent is for it to eventually pull from a shared, reusable Mise en
Place prep-time reference (a list of items → standard prep time) that doesn't exist yet — that
reference list, and wiring this column up to it instead of manual typing, is future work, not
done here.

**New SQL to run:** `20_prep_sheet_schema.sql`, then `21_prep_sheet_seed.sql`.

**Prep sheet refinements (same day):**
- ON HAND changed meaning from the recipe's gram quantity to a 0-13 stock count (how many are
  currently prepped/ready) — `22_prep_sheet_clear_onhand.sql` clears the old gram values.
- Added a status field to prep items — TO DO / CHECK / FINISH / DONT DO, same pattern and
  button styling as the regular task list, but a separate concept from priority (DONT DO
  means "skip this item today," not "lowest priority" — priority stays 1-5) —
  `23_prep_sheet_status.sql`.
- Each dish header now shows a "Total prep" time — sum of that dish's items' Time to prep
  values (best-effort text parsing, minutes or hours).
- Station chips in Mise en Place now show a live count badge (e.g. "SKY 3/12" = 3 finished of
  12 total), and opening a section shows a full to-do/check/finish/don't-do breakdown row
  above the list — computed from `tasks.status` for normal stations, `prep_items.status` for
  prep-sheet stations.

**Prep sheet refinements, round 2:**
- Default status for every prep item is now DONT DO, not TO DO — items are opted out of
  today's prep by default; Richard ticks TO DO for what's actually needed today.
  `24_prep_sheet_min_required.sql` also resets all 69 existing SKY items to DONT DO.
- Added `min_required` (par level) per item — a 🚩 red flag now shows on any ingredient whose
  ON HAND count is below its minimum (blank ON HAND counts as 0). Seeded with a rough 2-4
  estimate based on how many dishes reuse that ingredient (1 dish → 2, 2 dishes → 3, 3+ → 4),
  matching Richard's own examples (Kopfsalatherz=2, Wildkräuter=2) — not real par levels yet,
  he should adjust per item.
- The TO DO / CHECK / FINISH counts in the summary row are now clickable — tapping one shows
  a flat list of just that status's ingredients across all dishes in the station, sorted by
  priority (critical first). DONT DO isn't included in this filter (it's meant to disappear
  from the working list, not be worked through).

**Prep sheet refinements, round 3 (legibility + min_required range change):**
- Full contrast pass across all of Mise en Place — inactive status buttons were at 40%
  opacity (nearly unreadable), now 85%. DON'T DO items no longer fade the whole row to 50%
  opacity (that killed legibility of every field, not just the name) — only the item name
  gets a strikethrough now. Field labels, dish total time, and summary counts all brightened.
  Driven by Richard's own eyesight and the real scenario of a tired cook writing tomorrow's
  list at the end of a shift.
- `min_required` values regenerated as a random 3-6 per item (was 2-4) — `24_prep_sheet_min_required.sql`
  was rewritten in place with the new range, still a placeholder Richard should adjust.
- The clickable TO DO/CHECK/FINISH filter got visible chip styling (border + ▾ arrow) — it
  existed before but had no visual affordance, so it read as plain text.

**Prep sheet refinements, round 4 (sticky headers + per-status time):**
- Both the station chips row and the to-do/check/finish/don't-do summary row are now sticky
  while scrolling (stacked: chips first, then summary), computed via measured topbar height
  in JS rather than a hardcoded offset.
- Replaced the single free-text "Time to prep" field with three separate numeric fields per
  item — `todo_minutes` / `check_minutes` / `finish_minutes` (`25_prep_sheet_stage_times.sql`).
  Rationale: how long an item still needs depends on which stage it's at (e.g. Kopfsalatherz:
  8 min if still TO DO, only 1 min if just needs a CHECK, 3 min if it's at FINISH) — not one
  fixed prep time. All three are visible and editable at once per item. Seeded with TO DO
  5-18 min (random, per Richard's instruction) and CHECK/FINISH scaled smaller — placeholders,
  not real timings.
- The summary row now also shows a live "⏱ X min left" total — sum, across the whole
  station, of each non-DONT-DO item's minute value for its *current* status. Each dish
  header's "Total prep" figure uses the same logic, scoped to that dish.

**Prep sheet refinements, round 5 (sticky header rebuild + legibility):**
- Rebuilt the sticky header as one physical block — topbar, station chips, and (when a prep
  sheet is open) the status summary are now nested inside a single `.tasks-sticky-header`
  wrapper with one solid background and one bottom edge, instead of three independently
  `position:sticky` pieces with JS-measured offsets. That JS math (topbar height + chips
  height) was fragile and left visible gaps/see-through seams on real devices. The Home
  back button, being part of this same block, is now always on screen — no scrolling needed
  to get back.
- Removed the strikethrough on DON'T DO item names — a tired cook writing tomorrow's list
  shouldn't have to decode struck-through text; the status button itself is enough of an
  indicator.

**Deployed to production:** the app is now live at
`https://richardcervenka111-create.github.io/chefos-app/` via GitHub Pages (a public repo,
safe since the only credential in the file is the Supabase publishable/anon key, which is
meant to be client-visible and is protected by RLS). Updates ship by re-uploading
`app/index.html` through GitHub's web UI (Add file → Upload files) — no build step, no CLI.

**Recipes — new AI features (2026-07-10):**
- **Photo scan now accepts gallery/file picks, not just the camera** — removed the
  `capture="environment"` attribute from the file input, which was forcing camera-only
  capture on mobile.
- **"✨ Generate method with AI"** button on the recipe form (next to "+ Add step") — sends
  the recipe's title + ingredient list to Claude with a `write_method` tool call and fills
  in the step rows with a generated method. Same direct-browser-to-Anthropic pattern and
  same stored API key as the photo scan.
- **Chef's Assistant** — new home-screen tile, a chat view (`chefAssistantView`) styled as a
  Michelin-starred executive chef persona (system prompt in `CHEF_ASSISTANT_SYSTEM_PROMPT`).
  Answers substitution questions, technique/prep advice, general kitchen judgment calls —
  concise, direct, no hedging. Session-only conversation (not persisted to the database),
  same Anthropic key reuse as the other AI features.
- **Cost control on Chef's Assistant (2026-07-10):** switched from Sonnet to Haiku
  (`claude-haiku-4-5-20251001` — much cheaper per token, still capable for this kind of
  conversational advice) and capped how much history gets sent per turn to
  `CHEF_CHAT_HISTORY_LIMIT` (8 messages) — previously the *entire* conversation was resent
  on every message, so cost grew the longer a chat went on. The full conversation still
  displays in the UI; only what's sent to the API is capped. Photo scan and Generate Method
  stay on Sonnet — they're one-shot calls (not compounding) and benefit more from the
  stronger model's accuracy on structured extraction/writing.
- **Known external dependencies, not app bugs:** the "insufficient credits" error on photo
  scan means Richard's Anthropic account has no billing/credit balance yet (console.anthropic.com
  → Billing) — nothing to fix in the app. The login code being 8 digits instead of 6 is
  generated by Supabase Auth itself, not controllable from app code or SQL; the login screen
  copy was already made digit-count-agnostic so it's cosmetic only.

**Kitchen Flow, phase 1 (2026-07-10):** clarified with Richard that this isn't a live
order/ticket (KDS) system — it's cross-station *visibility* into the same Mise en Place data
that already exists, so anyone (a sous chef, a head chef) can see what every station still
has to do, not just their own. Shipped as part of the existing Mise en Place screen rather
than a new one:
- **Station picker rebuilt as icon tiles** (`STATION_ICONS`, `.station-tile`), same visual
  language as the Home screen grid, replacing the horizontal chip row. Each tile shows a
  live finish/total count.
- **Overload warning:** any prep-sheet station with more than `STATION_OVERLOAD_MINUTES`
  (210 min = 3.5h) of remaining work — summed the same way as the "⏱ min left" figure —
  gets a 🔥 badge on its tile (`getStationRemainingMinutes()`). Only prep-sheet stations
  (SKY, Hot Line, Garde Manger, Desserts) carry per-item time data, so plain task stations
  don't get a badge — nothing to sum a workload from yet.
- **"All sections at once"** is the tile grid itself — every station's tile shows its own
  live stats simultaneously, so opening Mise en Place already is the overview; no separate
  dashboard screen was built (kept scope to one redesigned view, not two).

**Prep sheet expansion — Hot Line, Garde Manger, Desserts (2026-07-10):** extended the
SKY-style dish-grouped prep sheet to three more stations, seeded from Richard's real menu
documents (`db/26_prep_sheet_new_stations.sql`):
- **Source:** `Frühlingskarte Beschreib 2026.pdf` (Hotel Schweizerhof spring menu, 18 dishes)
  and `Küche beschreibung Menu 2.docx` (4-course tasting menu; an identically-named "Menu 3"
  file was confirmed a duplicate and ignored).
- **22 dishes, 132 items** across Garde Manger (5 dishes — cold starters/salads/tatars),
  Hot Line (11 dishes — hot mains, fish, poultry), and Desserts (6 dishes). No CHF prices
  were given in these documents (unlike SKY), so `price` is NULL for all of them.
  `min_required` (3-6) and the three stage-time fields are the same random-placeholder
  pattern as SKY — not real par levels or timings yet.
- **Station assignment is Richard's approved judgment call, not from the source
  documents** — the menus don't specify which kitchen station handles which dish. Richard
  confirmed the type-based heuristic (cold → Garde Manger, hot → Hot Line, dessert →
  Desserts) rather than providing an exact mapping; worth spot-checking once he's used it.
- **Not yet done:** `Jack's Brasserie_Speisekarten_Brasserie Menü3.pdf` was excluded — it
  only lists 2-3 flavor pairings per dish (e.g. "Zander — Kefen | Speck"), no component
  breakdown to build a prep sheet from. Also not yet done: adding any of these dishes as
  full Recipes (Richard floated this as optional, not committed to).

**Prep sheet expansion, round 2 — Lobby, Entremetier, BQT, Extra (2026-07-10):** all 8
`DEFAULT_STATIONS` now use the dish-grouped prep-sheet style (`db/28_prep_sheet_remaining_stations.sql`):
- **Lobby** is built on the real concept of the Hotel Schweizerhof Bern Lobby Lounge Bar —
  found via web search (schweizerhofbern.com/en/dining/lobby-lounge-bar): a Fugu-licensed
  sushi chef (Hironori Takahashi) serving sashimi/sushi plus mezze-style light dishes. Their
  actual itemized menu lives in an Issuu flipbook that couldn't be read by any available tool
  (image/canvas-rendered, not text) — so the 6 specific dishes seeded are a plausible
  reconstruction of that real concept, not verbatim from their menu.
- **Entremetier, BQT, Extra** have no real reference at all — Richard explicitly authorized
  filling these in from general kitchen-brigade knowledge for presentation purposes only
  (15 dishes total). Flagged in the SQL file header as provisional, to be replaced with real
  references later, same pattern as everything else in Mise en Place.

**Mise en Place — notes field (2026-07-10):** both task types (the flat checklist and prep
sheet items) now have a free-text notes field — `db/27_task_notes.sql` adds `notes` to both
`tasks` and `prep_items`. Shows inline on the task row (📝 prefix) and as an always-visible
input under each prep item's status buttons; edited in the task form for flat tasks.

**Kitchen Flow, phase 2 — AI prep sheet scan (2026-07-10):** the "add a new Mise en Place
station" ask is now self-service — the FAB button in any prep-sheet station now triggers
"Scan a prep sheet" instead of being hidden. Works exactly like the recipe photo scan (same
Anthropic key, same `scanOverlay` UI) but reads a *whole* prep sheet (photo or PDF) in one
call via a `record_prep_sheet` tool returning an array of dishes, each with its item list and
optional price. Claude's Messages API accepts PDF natively as a `document` content block (not
just images), so both photo and PDF uploads work — DOCX does not, since Claude's API has no
native document type for it (would need conversion first). After scanning, a review sheet
shows the dish/item count and lets the user pick an existing station or name a new one before
saving — this is how future stations should get built going forward, rather than manual
transcription each time.

**Renamed: "Mise en Place" → "Check List" (2026-07-10):** Richard's call — the feature's
user-facing name is now "Check List" everywhere in the app (home tile, screen title, scan
review sheet). Internal names (code comments, DB tables `tasks`/`prep_dishes`/`prep_items`,
function names) intentionally unchanged — renaming those risks breakage for zero user value;
this doc keeps using "Mise en Place" in older entries, which describe the same feature.

**Translated all prep-sheet data to English (2026-07-10):** `db/29_translate_prep_sheets_en.sql`
— 42 dish renames + 170 item renames covering every German name seeded across files 21/26/28
(the app UI was already fully English; only the data was German). Name-based updates, safe to
re-run. One ambiguity handled with a scoped update ('Salat' → 'Lettuce' on Lobby sandwiches
but 'Salad' on the Extra staff meal). Deliberately NOT translated: Rösti (the Swiss dish's
name in English too), Sauce Bordelaise / Côte de Boeuf / Baba au Rhum etc. (French culinary
terms), and proper product names (Belper Knolle, Ribelmais, Luma, Morucha, Taggiasca). Also
fixed two typos while at it: 'Ceasar Dressing' → 'Caesar Dressing', 'Strawberry Compté' →
'Strawberry Compote'. Future scans via the AI prep-sheet import will save whatever language
the source sheet is in — if Richard wants everything kept English going forward, the scan
prompt could translate at import time (not done yet, flag if wanted).

**Multi-language UI, v1 (2026-07-10):** real infrastructure, not a token gesture — a
`TRANSLATIONS` dictionary + `t(key)` lookup (falls back to English, then the key itself, so a
missing translation never breaks the UI) + `applyTranslations()` (walks `[data-i18n]` /
`[data-i18n-placeholder]` elements) + a `.lang-switch` dropdown (English/Deutsch/Français/
Italiano/Slovenčina) on the login screen and Home topbar. Language is a **per-device**
`localStorage` setting, deliberately not synced via the account — two cooks sharing one
kitchen login may each want their own phone in a different language. `refreshCurrentView()`
re-renders whichever JS-templated screen is open so it picks up the change immediately too.

**Coverage right now is intentionally partial, not full-app** — translated: login screen,
Home (kicker + all 7 tile labels), and Check List's status labels (TO DO/CHECK/FINISH/DON'T
DO) + field labels (On hand/Priority/Note). **Not yet translated:** Recipes, Ingredients,
Order List, Schedule, Fridge Temp, Chef's Assistant screens, and every form (20-field recipe
form, ingredient form, task form, etc.) — those remain English-only. This was a scope call,
not an oversight: each of those is many more strings, spread across large template-string
render functions, and doing all of them in one pass risked breaking something across a
4000+ line file. The dictionary/`t()`/`data-i18n` pattern is proven and ready to extend
screen-by-screen — natural next slice is Recipes (highest-traffic screen) or Check List's
remaining chrome (dish headers, "min left", filter labels). Real kitchen *data* (recipe
names, ingredient names, staff names, dish names) is never translated regardless — that's
content, not UI chrome, and stays in whatever language it was entered in.

**Check List "All" view fixed (2026-07-10):** the "All" tile was a leftover from before every
default station became a prep sheet — it rendered the old flat `tasks` table, which is
basically empty now, so "All" showed nothing real. Rebuilt as an actual cross-station view
(`renderAllStationsView()`): a strip listing every station with its own outstanding time
(tap one to jump straight in), then one flat worklist of every non-DON'T-DO item across
every station, longest job first, each row tagged with its station icon + name + dish.
Also fixed the station-tile badge — it showed `finish/total` where `total` counted every
item ever seeded (hundreds, mostly DON'T DO by default), so it looked permanently stuck
(e.g. "0/73"). Now shows `finish` against only what's been opted in (`todo+check+finish`),
so it actually moves as items get worked.

**Swipe-back gesture (2026-07-10):** since every screen is a shown/hidden div rather than a
real URL, there was no browser history for iOS's edge-swipe to hook into. Added a manual
touch listener: a swipe starting within 24px of the left edge, dragging right 70px+ without
much vertical drift, clicks whatever `.back-btn` the current screen already has — reuses
each view's existing back-navigation rather than a separate destination map.

**Master ingredient database — paused for a decision, not started (2026-07-10):** Richard
attached `CLAUDE CHEFOS MASTER DB.md`, a full spec for a ~20,000-row, multi-table ingredient
database (suppliers + real SKUs, HACCP storage rules, portioning/yield %, full nutrition +
allergens, sustainability/carbon footprint, culinary pairing notes, image pipeline, FTS5
search, REST API, SQLite-first with Postgres migration notes) — a fundamentally different,
much bigger architecture than the current `ingredients` table (535 rows, one flat table)
that Recipes/cost/nutrition already depend on. Did not start building this — it's a
major scope and cost decision (20,000 AI-generated rows is roughly 37× the effort of the
535 already priced, which itself took a background agent real time) that needs Richard's
direction on: does this replace or sit alongside the current table; does he want it built
in phases (500 → 2,500 → 10,000 → 20,000 per the doc's own gates) rather than all at once;
and is he aware of the likely API cost before committing. Asked him directly rather than
silently spending significant time/money on an assumption.

**Ingredients expanded to ~1300 + season/storage filters (2026-07-10):** Richard scoped the
master-DB question down to something concrete — keep the current simple `ingredients` table
architecture (not the full 20k-row multi-table spec), extend it with the two new fields he
actually needs, and grow from 535 to roughly 1300 ingredients for a stronger presentation.
- `db/30_ingredients_storage_season.sql` — adds `storage_type` (Dry Storage/Refrigerated/
  Freezer/Room Temperature) and `seasons` (text array, subset of Spring/Summer/Autumn/Winter,
  empty = year-round/not seasonal) columns. Schema-only, safe to run immediately.
- Background agent complete. `db/31_ingredients_backfill_storage_season.sql` — 533 updates
  filling `storage_type`/`seasons` for every existing ingredient (533, not 535 — the real
  distinct count) + 83 updates splitting `Produce` into `Fruit`/`Vegetable`.
  `db/32_ingredients_expansion_new.sql` — 730 new ingredients (533+730=1,263 total): Seafood
  as its own category (80 species-level items incl. Swiss lake fish), deeper Japanese/Asian
  pantry, Swiss AOP cheeses, nuts/legumes/alcohol/condiments/baking. Verified zero name
  collisions with the existing 533. Same estimate-and-flag honesty standard as the original
  533. Not yet run against the live database — files are ready, waiting on Richard.
- App: Ingredients screen now has two more filter-chip rows (season, storage type) alongside
  the existing cuisine row — all three combine (AND), e.g. Universal cuisine + Autumn +
  Refrigerated. Season filtering is strict: a year-round item (empty `seasons`) won't show
  under a specific season, since the point is "what's actually in season now." Both fields
  are also editable per-ingredient in the add/edit form (a storage dropdown + four season
  checkboxes), not just settable via bulk SQL.

**Noted for later — AI feature monetization + schedule coverage assistant:** Richard wants to
revisit two things once there's more to build on: (1) monetizing Chef's Assistant / the AI
features generally, most likely by bundling them into the paid Chef Pro / Restaurant
subscription tier rather than metering per-user (he separately floated letting the head chef
set a per-employee usage limit — parked, not designed); (2) extending Chef's Assistant to
help with real schedule-coverage problems (a cook calls in sick — who's qualified/free to
cover, or how to redistribute their tasks) — this needs the assistant to actually see live
Schedule data (shift_codes/staff_members/schedule_assignments) rather than being a
data-blind chatbot, which is a real integration, not just a prompt change. Neither is
built yet.

**Nutrition — complete.** `db/13_nutrition_schema.sql` adds kcal/protein/carbs/fat per 100g
to ingredients, `db/14_nutrition_seed.sql` fills all 535 (374 `standard` well-established
values, 161 `estimated` for composite/branded/prepared items — see file header).
`computeRecipeNutrition()` mirrors the cost engine exactly (name matching, unit conversion to
grams, sum) and is wired into the recipe detail view. Piece-count-only lines can't convert and
are excluded, same transparency pattern as cost.

**Known simplification:** neither the Mise en Place quick-add nor the Order List filter
ingredients/recipes by station beyond what's explicitly tagged — there's no automatic
inference of "which ingredients belong to Hot Line." Recipes need their Station field set
(now possible via the edit form) before they'll appear in that station's quick-add list.

## Ingredients & Pricing — earlier this session

- Origin/season/substitutes research completed for all 535 ingredients
  (`db/10_ingredient_substitutes_seed.sql`) — season filled for 122/535 (only genuinely
  seasonal fresh produce/herbs/fruit/truffle/mushroom; left blank for meat/poultry/eggs/dry
  goods/spices/sauces/dairy/alcohol/most seafood, treated as year-round in professional
  kitchen sourcing), substitutes filled for 502/535 (blank only for ~33 generic/placeholder
  or genuinely irreplaceable items like water or plain salt).

## Phases 2–7

Intentionally not detailed yet. Each phase gets its full breakdown when we reach it — writing
it out now would mean designing around decisions (e.g. what Phase 1 actually ships) that don't
exist yet.

## Phases 2–7

Intentionally not detailed yet. Each phase gets its full breakdown when we reach it — writing
it out now would mean designing around decisions (e.g. what Phase 1 actually ships) that don't
exist yet.

## Investor presentation — `app/presentation.html` (2026-07-10)

Standing rule from Richard: this file gets updated after any subsequent shipped
task/feature/code change so it stays an accurate live snapshot — not just a one-time export.
Content: real KPIs (recipe/ingredient/station counts), 3 core-benefit cards (2 live, 1
vision — supplier collaboration is NOT built), a pseudo-Gantt roadmap (Chart.js horizontal
bars: solid/sage = shipped with real dates, hatched/copper = illustrative future quarters,
Phases 2–7 mapped from the table above), 3 pricing tiers (illustrative, not Richard-approved
or committed), and an illustrative ARR chart (2026–2030, explicitly labeled projection, zero
paying customers today). All editable data lives in one JS block at the top of the file's
script (`KPIS`, `BENEFITS`, `ROADMAP`, `REVENUE_ILLUSTRATIVE_CHF`) — update those arrays, not
the markup, when new facts land. Uses Chart.js via CDN (fine here — this is a real hosted
file on GitHub Pages, not the sandboxed Artifact tool, so external scripts are allowed).

## Ingredients — Food Type filter + new `app/planning.html` (2026-07-10, later still)

- **Ingredients: Food Type filter chips** — new row (Fruit/Vegetable/Dairy/Meat), exact-match
  against `category`, combinable (AND) with the existing cuisine/season/storage-type rows —
  same pattern, same `renderIngredientList()` filter chain.
- **`app/planning.html` — new file.** Companion to `app/presentation.html`, answering Richard's
  ask for a day/week/month breakdown with click-to-expand daily detail and top-3-priorities
  tracking (done vs. in-progress vs. planned) at each timeframe. Structure: `TOP3` object (day/
  week/month, each 3 items with a status dot) + `DAYS` array (one object per day worked, with an
  `accomplished` bullet list and a `planned` carry-over note) that auto-groups into weeks and
  months in JS (`isoWeekLabel`/`monthLabel`) — adding a new day going forward is just pushing one
  object to `DAYS`, no manual regrouping needed. Same dark theme/CSS variables as
  `presentation.html`, no external dependencies besides the shared visual language (no Chart.js
  needed here). Seeded from the three real work days logged in this file (2026-07-08/09/10).

## Login screen — "check Trash/Spam" hint (2026-07-10, later still)

Richard reported the login code lands in Trash for some email providers (not every provider
inboxes it directly, unlike the one he's been testing with). Added a small hint line under the
code-entry step (`.login-hint`, translated in all 5 UI languages via `checkTrashHint` in
`TRANSLATIONS`): "Don't see it? Check your Spam and Trash folders too." Shows right after
`sendLoginCode()` reveals the code-entry step, so it's visible before the user even needs it.

## Investor presentation refocused on Switzerland / canton Bern (2026-07-10, later still)

Richard asked for the presentation to be more realistic and scoped to the Swiss market,
starting in canton Bern, rather than a vague global pitch:
- New "Market" section with real, sourced numbers: Switzerland ~32,000 F&B establishments,
  CHF 25–28bn/year foodservice revenue (GastroSuisse Branchenspiegel 2025), and canton Bern
  ~3,500 establishments — explicitly flagged as a population-share estimate (~12% of the
  national figure), not an official GastroSuisse cantonal count (no such breakdown is publicly
  available).
- Hero copy, status pill, and Financials intro now state the canton-Bern-first go-to-market
  explicitly instead of implying a broad/global launch.
- Roadmap's forward (unshipped) phases rewritten as a real geographic expansion ladder: canton
  Bern go-to-market → neighbouring cantons (Fribourg, Solothurn, Vaud, Neuchâtel) →
  German-speaking Switzerland (Zürich, Basel, Lucerne, Aargau) — replacing the old vague "Scale
  — multi-market + supplier B2B marketplace" bar.
- Supplier-collaboration vision card now names real Swiss foodservice wholesalers (Transgourmet,
  Prodega) instead of generic "supplier feeds".
- **Revenue chart rebuilt bottom-up** instead of an unexplained growth curve: a new assumptions
  table under the chart shows, per year, the region, the hypothetical paying-kitchen count, the
  blended ARPU (CHF 89/month = 60% Chef Pro @49 + 40% Restaurant @149), and the resulting ARR —
  fully transparent math instead of a bare line. Kitchen counts: 20 (canton Bern, 2027) → 80
  (canton Bern, 2028) → 250 (Bern + neighbours, 2029) → 600 (German-speaking CH, 2030). Still
  explicitly illustrative/not committed — zero paying customers today.

Not yet uploaded to GitHub Pages — Richard needs to re-upload `presentation.html` for the link
to reflect these changes.

## Check List — manual station + dish creation (2026-07-10, later still)

Two real people are now testing Check List live on separate phones (via Richard's shared
login, at two real venues), and the only way to create a new station or a new dish/composition
was via the AI photo/PDF scan. Added a manual path so this doesn't depend on having a paper
sheet to photograph, and fixed a real cross-device persistence gap along the way:

- **Cross-device station persistence fix.** `PREP_SHEET_STATIONS` was an in-memory-only array —
  a station created via AI scan on one phone only lived in that browser tab and vanished for
  everyone else on reload. `loadAppData()` now syncs any station name found on a real
  `prep_dishes` row into `PREP_SHEET_STATIONS` every time it loads (on init and after every
  save), so a station created on any device shows up for every device on next load — no new
  table needed, same pattern the flat `tasks` station list already used.
- **"+ Add dish" manual entry** (`prepDishFormView`, `savePrepDishForm()`): pick an existing
  station or type a new one (`+ New station…`, same pattern as the task form), name the dish,
  optional CHF price, then a repeatable list of "what it's made of" item rows (`+ Add item`,
  reusing the exact ingredient-row add/remove pattern from the recipe form). Saving inserts the
  same `prep_dishes` + `prep_items` shape the AI scan already produces, so a manually typed dish
  behaves identically afterward (editable on-hand/priority/status/times, same flag/clock logic).
- **"+ Add item" on an existing dish** (`openAddPrepItem`/`saveAddPrepItem`): a small `+` button
  in each dish card's header opens a one-field sheet to append one more component to that dish's
  composition without recreating the whole dish.
- **FAB reworked**: the FAB in any prep-sheet station now opens a choice sheet — "Add a dish
  manually" or "Scan a prep sheet" — instead of jumping straight to the scanner, mirroring the
  existing Recipes "Type it in / Scan a photo" choice pattern.

## Check List — "+ New Section" tile fix (2026-07-10, even later)

Richard reported that creating a new Check List section still didn't work after uploading the
previous batch. Root cause: the only way to reach "add a dish / new station" was the FAB inside
an *already-open* existing station — there was no way to start a brand-new section directly
from the station grid itself, which is what he was actually trying to do.

Added a dashed "+ New Section" tile at the end of the station grid (`renderTaskChips()`) — tap
it, type a name, and it goes straight into the manual "Add a dish" form pre-set to that new
station name, so the very next thing typed becomes that section's first dish. Reuses the same
`showAddDishForm()`/`savePrepDishForm()` path as everything else — no separate save logic.

## Check List — real, averaged prep times (2026-07-10, even later)

Manually-created dishes had no way to set a time estimate, and every existing time value was
just a random 5-18 min placeholder from the original seed SQL — never a real observation.
Richard asked for a way to log real time whenever a user wants, with repeated entries
averaging together rather than overwriting.

- `db/33_prep_item_time_samples.sql` — adds `todo_minutes_n` / `check_minutes_n` /
  `finish_minutes_n` sample-count columns to `prep_items` (default 0).
- The "⏱ X min" badge on every prep item (only shown once it's not DON'T DO) is now a tappable
  button — logs how long the item took *at its current stage* (TO DO/CHECK/FINISH). First real
  submission for a stage replaces the seeded placeholder outright (count 0 → 1, so a random
  guess never gets averaged against a real number); every submission after that properly
  averages into the running value using the sample count, so the figure gets more accurate the
  more people log it — the crowd-sourced replacement for the original random placeholders.

**New SQL to run:** `33_prep_item_time_samples.sql`.

## Public trial scoped: 2026-08-01, 25 users, multi-team via QR invite (2026-07-10, direction-setting)

Richard set a concrete public-launch target: **2026-08-01**, a trial for **25 people across
multiple restaurants**, each restaurant forming its own team by sharing a QR code — not one
single shared kitchen like the current pilot. Scope for this trial is deliberately narrow:
**Check List, Chef's Assistant, Ingredients, Recipes** only (Order List, Schedule, Fridge Temp
are out of polish-scope for now, not being removed). Recorded in `app/presentation.html`
(roadmap: "Public trial prep" + "Public trial" bars, new KPI) and `app/planning.html` (top-3
priorities at all three timeframes now center on this).

**What this needs, technically — not yet built:**
- **Email login for any address.** Currently blocked by Resend's sandbox restriction (can only
  send to Richard's own verified email) — flagged earlier this session. Needs either a verified
  sending domain in Resend (DNS records — Richard's action item) or a temporary switch to
  Supabase's built-in mailer. This is a hard blocker for 25 real people signing in with their
  own emails and needs to happen well before Aug 1.
- **Multi-team architecture.** The schema already supports this at the RLS level — `kitchens`
  (one row per restaurant) and `profiles.kitchen_id` already scope every table's row-level
  security by kitchen. What's missing is the *application* layer: today every signup is
  auto-attached to "the one kitchen that exists so far" via the `handle_new_user` trigger
  (`db/01_schema.sql`), a placeholder explicitly labeled for this exact future work. Needed:
  a "create your own kitchen" flow for whoever starts a new team, a shareable invite
  link/QR code (client-side QR generation, no third-party service — kitchen UUIDs are already
  unguessable, so the invite link itself doubles as the invite token for v1), a join flow that
  updates the joining user's own `profiles.kitchen_id`, and new RLS policies (insert on
  `kitchens`, update-own-row on `profiles`) since neither exists yet. Not started.
- Optional, floated but not committed: a chat feature within a team ("popripade pridať chat").

## Multi-team (QR invite) + closed-trial access gate — built (2026-07-10, still later)

Richard confirmed: build the multi-restaurant teams system now, and gate the whole trial so
every email has to be manually approved by him first (friends/acquaintances, not open signup).
`db/34_teams_access_gate.sql`:

- **Teams.** `kitchens` + `profiles.kitchen_id` already scoped every table's RLS by kitchen
  (designed in from Phase 1a) — what was missing was the application layer. New signups now get
  `kitchen_id = null` (the trigger no longer auto-attaches everyone to "the one kitchen that
  exists so far") and pick one themselves: **create their own kitchen** (names it, becomes its
  first member) or **join one via an invite link/QR** a team member shares (the link carries the
  kitchen's id — already an unguessable UUID, so it doubles as the invite token, no separate
  invite-code system needed for v1). New RLS: insert on `kitchens` (any logged-in person), select
  on `kitchens` (any logged-in person can read a kitchen's *name* — needed to show "Join
  <name>'s team?" before joining), update-own-row on `profiles` (needed to set your own
  `kitchen_id`). Existing users (Richard + the 2 pilot testers) are unaffected — they already
  have a `kitchen_id`, so none of this interrupts them.
- **Access gate.** New `access_requests` table (email, status pending/approved/denied). Anyone
  without a `kitchen_id` yet gets checked against it: no request → one is filed automatically and
  they see "waiting for approval"; approved → they proceed to create/join a kitchen; denied →
  told plainly. Richard is flagged `is_admin = true` (matched by his email) and gets a new
  "Admin" tile on Home (hidden for everyone else) listing pending requests with Approve/Deny.
  This is a genuine security boundary, not just a UI gate: every other table's RLS already
  requires `kitchen_id in (select kitchen_id from profiles where id = auth.uid())`, and an
  unapproved user's `kitchen_id` is null — so `x in (select null)` never matches, meaning an
  unapproved account can't read/write any real kitchen's data even via direct API calls.
- **My Team screen** (new Home tile): shows the kitchen's name, a copyable invite link, a native
  "Share" button (`navigator.share`, mobile only), and an actual scannable QR code — generated
  fully client-side via a vendored copy of `qrcode-generator` (Kazuhiko Arase, MIT license,
  ~2,300 lines inlined right after the Supabase CDN script tag) so no invite link/kitchen id ever
  goes through a third-party QR-image service. Verified the vendored library before shipping:
  compared its output for a real invite URL against Python's independently-implemented `qrcode`
  library — same QR version and module count for the same input (differences were only in mask-
  pattern choice, which is implementation-dependent and doesn't affect scannability).

**Known v1 limitations, not built:** no "switch teams" UI once someone has joined one (one-time
choice for now); no automated email notification when a new access request comes in — Richard
checks the in-app Admin tile (chose this over building a server-side email-notification function,
which would be new backend infrastructure this buildless single-file app doesn't otherwise need,
especially while the Resend email pipeline is already the thing that needs fixing first).

**New SQL to run:** `34_teams_access_gate.sql` (also flags richard.cervenka111@gmail.com as
`is_admin`).

**Still blocking the 2026-08-01 trial:** email login for non-Richard addresses (Resend sandbox
restriction) — unrelated to this batch, still needs Richard to verify a sending domain or switch
to Supabase's built-in mailer.

## Big feature dump — 4 planning documents (2026-07-11)

Richard attached 4 files (`Check list.txt`, `General.txt`, `Order list.txt`, `Recipe.txt`) with
a large backlog. Triaged rather than built blindly — most of it is real, well-specified work;
some of it is explicitly his own "just note it, not now" items; a few needed a decision before
any code could be written correctly.

**Decided today:**
- Label printing (Check List + Recipes + General's "Print Labels" icon): **use the device's
  native print dialog** (`window.print()`) — works with whatever printer is already paired to
  the phone/iPad (AirPrint etc.) without ChefOS needing a printer-specific driver. Real
  WiFi/Bluetooth printer *auto-discovery* stays parked until a specific printer model is chosen.
- Login stays **email-code only, no password** — the "email + password twice" note in
  General.txt is parked as a future idea, not built (adds real friction, and the current
  passwordless flow already works).
- Access-request **email notifications** stay parked — the existing in-app Admin tile is enough
  for now; a real notification would need a mail-sending server (Supabase Edge Function), which
  this buildless app doesn't otherwise need.

**Explicitly parked by Richard himself (his own wording), logged so nothing gets lost, not
started:** payment system; productivity-based staff bonuses + referral rewards; GPS-geofenced
check-in/check-out with automatic overtime calc, contract-scan legal review, and step/movement
tracking (real labor-law and employee-privacy implications — needs real legal review before any
code, not just "later"); pass-station camera + AI plate-quality check; waste tracking (design
not settled yet — his words: "spolu na to prejdeme"); a non-professional/social-media variant
with comment moderation (his own flag: "ak sa spustí bez security check tak môžeme zhasnúť").

**Queued, not started yet (needs its own build pass):** master/admin *device*-level permissions
(distinct from user roles — device pairing/fingerprinting, more complex than it sounds); team
chat + notifications icon (doable via Supabase Realtime, but a real feature, not a quick add);
monthly Chef's Assistant "5 good / 5 bad" report (needs a real month of usage data to be
meaningful — premature before the trial even starts); bar/drinks recipes + check list (a real
content-domain expansion, worth scoping properly rather than bolting on); Order List
visual rebuild to match Check List's icon-tile style + per-section order-count badges;
Fridge Temp via per-fridge QR scan with recurring reminders; device-level order-day restrictions
with blinking alerts.

**Being built now, this session:** recipe double-save bug; sticky Save bar while editing a
recipe; 🚩 flag restricted to priority-1 items only; hide/delete a Check List task or whole
section; Order icon (Check List item + recipe ingredient row) opening a qty/unit/note dialog;
Print Labels queue + native print; Check List sticky header collapsing to a mini icon+name+
status bar on scroll; de-duplicating identical item names across dishes within one station
(shows once with a "×N" count, one status update applies to all); Recipes screen visual rebuild
to match Check List (category icon tiles, fixed top bar, show/hide settings); ingredient "i"
panel gets a short Chef's Assistant-written blurb (flavor, origin, season) with a Wikipedia
link; recipe category reordering (cold → Asia/sushi → soups → sauces/marinades → meat →
desserts → oils); sort recipes by newest.

## First batch from the 4-document dump — shipped (2026-07-11)

- Recipe double-save bug fixed: a `_savingRecipeForm` guard now blocks a second `saveForm()`
  call while the first is still in flight (fast double-tap on Save was the real cause — both
  calls raced to insert before `formEditingId` got set).
- Reviewed the recipe edit form's sticky Save bar — CSS already uses the same proven
  `position:sticky` pattern as every other screen; couldn't reproduce a real detachment without
  a live device. Flagged to Richard to re-test and describe exactly when/how it happens if it
  persists, rather than guessing at a fix blind.
- 🚩 under-minimum flag now only shows on priority-1 items (`isPrepItemUnderMin`).
- Check List: delete a single item (✕ on the row), delete a whole dish (🗑️ on the dish card,
  cascades to its items), delete an entire section ("Delete this whole section" at the bottom
  of a station's prep sheet — deletes every dish/item tagged to that station name, since a
  station isn't its own row, see `db/34_teams_access_gate.sql`'s notes).
- 🛒 "Add to Order List" button — on every Check List item and every recipe ingredient row
  (right next to the existing "i" button, as asked). Opens a small dialog (station, quantity,
  unit, note) and upserts into `order_list_items`, matching the ingredient by the same
  name-normalization the cost engine already uses; if there's no match yet, a bare-bones
  ingredient row is created on the fly rather than blocking the order. `db/35_order_list_notes.sql`
  adds the `notes` column this needed — also fixed a latent bug while touching this: the full
  Order List screen's bulk save previously didn't round-trip `notes` at all, which would have
  silently wiped any note added via the new quick-dialog the next time someone saved that
  screen; now it carries `notes` through both load and save.

**New SQL to run (in order):** `35_order_list_notes.sql` (in addition to the still-pending
`34_teams_access_gate.sql` if not run yet).

**Still queued from this batch, not started yet:** Print Labels queue + native print dialog;
Check List sticky header collapsing to a mini bar on scroll; de-duplicating identical item
names across dishes within a station; Recipes screen visual rebuild to match Check List;
ingredient "i" panel Chef's Assistant blurb + Wikipedia link; recipe category reorder + sort
by newest.

## Check List — hide (not delete) an item/dish/section (2026-07-11)

`db/36_prep_hidden.sql` adds a `hidden` boolean to `prep_dishes` and `prep_items`. Off by
default everywhere (counts, "All" view, station remaining-time, everyday rendering all exclude
hidden rows) — a "Show N hidden" toggle inside a station reveals them with an unhide (👁️)
control instead of the hide (🙈) one. Hiding a whole section hides every dish tagged to it in
one call; bringing a fully-hidden section back uses the same "Show hidden" toggle inside it
(no separate "unhide section" action needed). This sits next to, not instead of, the delete
option already shipped.

**New SQL to run:** `36_prep_hidden.sql`.

## ChefOS Master Board — new visual identity (2026-07-11)

Richard sent a reference file (`ChefOS_Master_Development_Board.html` — dark navy, teal accent,
sticky progress bar, localStorage checkboxes) and asked for a comprehensive version covering
everything shipped and everything planned, with a live pie-chart progress indicator and each
task tagged by who does it (him vs. me). Built `app/board.html`:
- Exact same palette/fonts as his reference (`#0A1A2F` bg, `#34F7D7` teal accent, `#9C949E`
  muted text, `-apple-system, Arial`) — declared his standing visual identity for ChefOS
  documents going forward, saved to memory.
- Added a CSS `conic-gradient` pie chart in the sticky top bar (no chart library, no canvas),
  updating live alongside the existing progress bar/stats.
- Added a "YOU" (gold `#F7C948`, new) / "ME" (teal, existing accent) tag on every task line.
- Sections: "✅ Shipped so far" (everything built this session, pre-checked true — fixed the
  reference script's checkbox-restore logic, which would otherwise have reset pre-checked boxes
  to false on first load since localStorage starts empty), then Priority 1/2/3 mirroring his
  reference's structure, populated from the actual current backlog (see "Big feature dump" and
  subsequent entries above) rather than his placeholder task names.

**Not yet decided:** whether `presentation.html` and `planning.html` (currently a different,
warm copper/sage palette) should be restyled to match this new navy/teal identity too — flagged
to Richard, not changed without his confirmation.

## Unified ChefOS visual identity applied everywhere (2026-07-11)

Richard confirmed: the whole visual should be unified ("všetko cely vizual bude jednotný").
Migrated `app/presentation.html` and `app/planning.html` off their original warm copper/sage
"kitchen notebook" palette onto the same dark navy/teal identity as `app/board.html`:
`#0A1A2F` background, `#122845` cards, `#34F7D7` teal accent (was copper), `#F7C948` gold as
the new secondary accent (replaces copper's "in-progress" role and sage's "warning/disclaimer"
role depending on context — see each file's own comments), `#9C949E` muted text, Georgia serif
headings dropped in favor of the same `-apple-system, Arial` used everywhere else. Chart.js
colors in presentation.html's roadmap/revenue charts updated to match. All three ChefOS
documents (presentation, planning, board) now share one CSS variable naming scheme
(`--bg/--paper/--paper-raised/--ink/--ink-dim/--ink-faint/--rule/--accent/--gold`), so future
edits only need to touch one place's definitions to stay in sync.

## board.html → tasklist.html + timeline (2026-07-11)

Renamed `app/board.html` to `app/tasklist.html` ("Task List") per Richard's request. Added:
- **% back into the top stats row** (was only inside the small pie chart before).
- **A second, always-visible bar below the top bar**: an interactive month → week → day
  timeline (click to expand), showing everything shipped and on which real date — ported the
  same accordion pattern from `planning.html`, restyled to `tasklist.html`'s existing hardcoded
  navy/teal colors (this file doesn't use CSS custom properties, unlike the other two).

## Check List row rebuilt to match Richard's sketch + real timer + Print Labels (2026-07-11)

Richard sent a hand-drawn row-layout sketch (`Check list.txt` item 9's reference). Rebuilt
`renderPrepItemRow()` to exactly 3 lines, all in the same monospace font as on-hand/priority:
1. Name + 🚩 flag + ON HAND + PRIORITY (inline, right-aligned fields)
2. TO DO/CHECK/FINISH/DON'T DO + ⏱ time badge + ▶/■ timer button
3. Note + 🛒 order + hide + delete

**Real start/stop timer** (was previously just a manual "log a number" dialog): tapping ▶
stores a start timestamp in `localStorage` (device-local — deliberately not the database,
since only whoever's physically on that item right now is timing it) and shows a live MM:SS
while the screen is on. Tapping ■ computes elapsed time as `Date.now() - start`, which stays
correct even if iOS suspended the tab on a locked screen — "časovač ktorý sa dá stopnúť aj na
zamknutej obrazovke". Stopping opens the existing time-confirm dialog pre-filled with the
measured value (editable before saving), which still averages into `todo/check/finish_minutes`
exactly as before.

**Print Labels** — new Home tile. When a timer-measured time is saved, a "how many labels?"
prompt appears immediately after, per the sketch. Confirmed quantities go into a print queue —
deliberately `localStorage`, not a database table, since General.txt asked for "all labels
*this device* needs", not a kitchen-shared queue. The Print Labels screen lists the queue
(adjust qty, remove, or add one manually), and "Print All" swaps the whole printed page for a
label sheet via the browser's own native print dialog (`window.print()` — talks to whatever
printer's already paired to the phone/iPad via AirPrint etc., no custom driver needed for v1;
real Bluetooth/WiFi printer support stays parked until a printer model is chosen).

**Not yet live-tested on a real device** — the timer's lock-screen survival and the print
dialog specifically need Richard's own phone to confirm; flagged to him directly.

## Undo for deletes + button-style row polish + item info panel (2026-07-11, later)

Richard hit real data loss (deleted/hid something in Check List with no way back). Fixes:

- **Soft delete, not real delete.** `db/37_prep_soft_delete.sql` adds a `deleted` flag to
  `prep_dishes`/`prep_items` — "Delete" now just sets this flag; the row is never actually
  removed. A "🗑️ N deleted — restore" toggle appears inside a station (same pattern as "Show
  hidden," but kept as a separate concept: hidden = intentional/always-reversible, deleted =
  "meant to remove this, mistakes happen too"), listing each deleted dish/item with a one-tap
  ↩️ Restore. All counts/totals/"All" view already excluded `hidden` — now also exclude
  `deleted` everywhere.
- **Timer button now matches TO DO/CHECK/FINISH/DON'T DO exactly** (`task-status-btn
  status-timer`), not its own custom pill style — same shape/font/border, sage when idle, red
  when running.
- **Line 3 (note/order/hide/delete) restyled to the same button language as line 2** instead of
  small bare icons — `🛒 Order`, `ℹ️ Info`, `🙈 Hide`/`👁️ Unhide`, `✕ Delete`, all as
  `task-status-btn`s (delete gets a red `status-danger` variant).
- **New ℹ️ Info button per item** — opens the same info sheet recipes already use for
  ingredients (origin/season/price/substitutes, refactored the shared HTML-building into
  `ingredientInfoHtml()` so both reuse it), plus a new section on top showing how many times
  each stage's time (TO DO/CHECK/FINISH) has actually been logged vs. still being a seeded
  placeholder.

**New SQL to run:** `37_prep_soft_delete.sql`.

## Check List sticky header collapses on scroll (2026-07-11, later still)

Richard sent a screenshot of exactly the row to keep (to-do/check/finish/don't-do chips +
⏱ min-left pill) and asked that scrolling inside an open section collapse everything else down
to just that row plus the Home button. Implemented via a `.collapsed` class on `.sticky-header`
toggled by a scroll listener (`handleTaskScroll()`, threshold 44px, resets on entering Check
List) — hides the "Check List" title and the station-tile grid, keeps the Home button + the
summary row pinned. Also added, as requested: the open station's own icon + name now shows
inline in that summary row, right before the time-remaining pill.

## Check List: station-tile grid no longer sticky + back-to-top button (2026-07-11, later still)

Richard's screenshot showed the real problem with the previous "sticky header" fix: the
station-tile grid itself is tall (3 rows, more as he adds sections), so pinning it at the top
while scrolling ate most of the phone screen — not what "sticky header" was supposed to mean.
Fixed by scoping `#tasksView .sticky-header` to `position:static` by default, only switching to
`position:sticky` once it's actually collapsed down to just Home + the summary row (i.e. inside
an open station, scrolled past the threshold) — the tile grid itself (and the "All" view, which
has no summary row to collapse to) now scroll away normally like regular content, exactly as
asked. Added a small floating "⬆ back to top" button (bottom-left, appears past 300px of
scroll, smooth-scrolls to top) as the replacement way to jump back up — not scoped to Check
List only, since the same long-list problem applies to Ingredients/Recipes/Order List too.

## Summary bar now shows in "All" too, everywhere in Check List (2026-07-11, later still)

Richard: the to-do/check/finish/don't-do + time-remaining bar must be there always and
everywhere in Check List — it was being cleared out specifically for the "All" tile. Fixed
properly rather than just re-adding it: `getSectionCounts()` and `getStationRemainingMinutes()`
now aggregate across every station when called with `'All'`; extracted the bar's rendering into
a shared `renderPrepSummaryBar(station)` used by both a single station's prep sheet and
`renderAllStationsView()`; the to-do/check/finish click-to-filter now also works inside "All"
(filters the flat cross-station worklist). Side benefit: since the bar now has real content in
"All" too, the scroll-collapse behavior from the previous fix applies there automatically —
scrolling "All" now also collapses down to Home + this same bar, not just individual stations.

## Button-style consistency, collapsible note, section visibility picker (2026-07-11, later still)

- **Dish-header buttons** (+ Add Item / Hide / Delete) restyled from bare icon buttons to the
  same bordered `task-status-btn` look as TO DO/CHECK/FINISH/DON'T DO, with text labels — matches
  Richard's screenshot request to use this one button design everywhere, not icon-only buttons.
- **Note collapses to a single small button** ("📝 Note" / "📝 Note ✓" if one's already saved)
  instead of a full-width input always taking its own line — tapping it expands into an
  editable field. Cuts the item row down further, per "čo najmenší počet riadkov."
- **Timer stays in the same row as TO DO/CHECK/FINISH/DON'T DO** — already true from the earlier
  sketch-matching pass, confirmed unchanged.
- **Delete already asks to confirm** before removing an item, a dish, or a whole section
  (`deletePrepItem`/`deletePrepDish`/`deleteStation` all use `confirm()`) — and since the soft-
  delete change earlier today, anything deleted is restorable via "N deleted" anyway. No change
  needed here, just confirmed it already does what was asked.
- **New "👁️ Visibility" tile** in the Check List grid — opens a sheet listing every section with
  a Visible/Hidden toggle per section, controlling which tiles show up in the grid at all
  (separate from hiding a section's *contents*, which stays a different, already-shipped
  feature). Deliberately device-local (`localStorage`), not shared kitchen-wide — this is
  personal declutter (e.g. hiding a test section someone created by accident), not something
  that should change what other staff see on their own phones.

## Check List header: Home + summary bar now ALWAYS pinned, no scroll needed (2026-07-11, later still)

Richard asked for this three times in a row with the same screenshot — the previous
scroll-triggered collapse wasn't good enough. Restructured properly instead of tuning
thresholds: the section-tile grid (icons, overload badges, + New Section, Visibility) no
longer lives inline in the sticky header at all — it moved into a ☰ picker sheet, opened by
tapping the new ☰ button next to Home, or by tapping the section name/icon inside the summary
bar itself. `#tasksView .sticky-header` is now unconditionally `position:sticky` — just Home +
☰ + the to-do/check/finish/don't-do + time row, pinned from the very first render, in every
section and in "All," no scrolling required. Removed the now-obsolete `handleTaskScroll()`
scroll listener and `.collapsed` class entirely — nothing left to toggle. Selecting a section
from the picker (or the "All" view's per-station strip) closes the picker and jumps straight
in, same as before.

**This is a real navigation change, not just styling** — flagged to Richard to test the ☰
picker, section switching, "+ New Section," and "Visibility" all still work as expected on his
phone before relying on it during service.

## Three bug fixes: timer label, "All" default list, note field (2026-07-11, urgent)

- **Timer button now says "▶ Start" / "▶ MM:SS · ■ Stop"** — was still icon-only, missed in the
  earlier button-label pass.
- **"All" no longer shows every non-DON'T-DO item by default.** That was the original design
  (a permanent cross-station worklist) but Richard explicitly does not want it — now shows
  nothing until "to do"/"check"/"finish" is tapped in the summary bar, exactly like the
  request. The per-station strip above it is unaffected.
- **Note field**: replaced the fragile tap-button→auto-render→`onblur`-closes pattern (which on
  mobile likely required a second tap to actually focus the field, and could leave it stuck
  open if blur didn't fire cleanly) with: tap "📝 Note" → field renders AND is immediately
  focused via `.focus()` right after the re-render → type → tap an explicit "✓ Done" button to
  collapse it back, instead of relying on blur timing at all.

## Item row redesign: ⋮ menu + consolidated hide picker (2026-07-11, later still)

Richard: line 1 should be TO DO/CHECK/FINISH/DON'T DO + a "⋮" that expands more actions; line 2
should be notes/order/info/timer; and hide was "different" after unhiding something, so move
hiding to one place instead of scattered per-item buttons.

- **Line 2 (status row):** TO DO/CHECK/FINISH/DON'T DO + a single "⋮" button, opening a small
  sheet with "✕ Delete this item" (the only action left there now that hide moved out).
- **Line 3:** 📝 Note, 🛒 Order, ℹ️ Info, ⏱ time badge, ▶/■ Timer — all together.
- **Hiding moved to the dish name.** Tapping a dish's name opens a picker: a "🙈/👁️ whole dish"
  toggle at the top, then every item in that dish with its own visible/hidden toggle — one
  place to see and change hide state for a whole dish at once, instead of hunting for a small
  button on each row. Removed the dish header's standalone Hide button (redundant with this)
  and the per-item Hide action.
- Verified the underlying sort order was already correct (hidden items keep their real
  `sort_order` position when later shown again) — the "different after unhiding" complaint was
  most likely the scattered-button UX itself being error-prone on mobile, which this
  consolidation should fix directly. Flagged to Richard to confirm with a specific repro if it
  still happens.

## Multi-select status filter in the summary bar (2026-07-11, later still)

"to do"/"check"/"finish" in the summary bar were mutually exclusive (tapping one cleared any
other). Changed `prepFilterStatus` (single value) to `prepFilterStatuses` (a Set) — tapping
multiple chips combines them (shows items matching any of the selected statuses), tapping an
active one again removes just that one. Applies everywhere this filter exists: a single
station's prep sheet and the "All" cross-station view.

## Six-part batch: visibility sync, custom icons, row layout, Order List redesign (2026-07-11, later still)

1. **"All" respects section visibility.** The per-station strip, the flat cross-station worklist,
   and the aggregated to-do/check/finish/time counts in "All" now all exclude sections hidden
   via the Visibility picker — previously only the picker itself respected it.
2. **Custom icon per new section.** `db/38_station_icons.sql` — new kitchen-shared
   `station_icons` table. Creating a section now shows a grid of ~30 curated
   restaurant/kitchen-relevant emoji to pick from (`STATION_ICON_CHOICES`), saved alongside
   the station and loaded into `_customStationIcons` on every `loadAppData()` — `stationIcon()`
   checks this before falling back to the hardcoded defaults or the generic 📍 pin.
3. **Row layout, per Richard's corrected screenshot:** the ⏱ average-time badge moved up into
   the same row as ON HAND/PRIORITY; ℹ️ Info moved out of its own button into the "⋮" menu
   alongside Delete.
4. **Section Visibility moved into the summary bar itself** (between the section name and the
   time-remaining pill) instead of living at the bottom of the station-picker grid.
5. **Order List rebuilt around what's actually ordered.** Opening it now shows a summary —
   grouped by section, each row showing name/quantity/unit/notes, with a ✕ Remove — sourced
   directly from `order_list_items` across every station, not the full 1,263-ingredient
   checklist. The original browse-and-check flow (station chips + search + full list) still
   exists, now reached via "+", and returns to the summary on Save.
6. **Reviewed the whole file for consistency**: no `onclick`/`onchange` handler calls an
   undefined function, no duplicate function definitions, no `getElementById` call targets a
   missing element — checked programmatically, not just by eye.

## Four fixes: stale counts, Visibility label, timer size, mobile auto-zoom (2026-07-11, later still)

1. **Zero counts on opening Check List from Home.** `showTasks()` now calls `await
   loadAppData()` before rendering, instead of trusting whatever was already in memory — closes
   off any staleness window between login and opening Check List.
2. **"👁️ Visibility"** now has its text label in the summary bar, not just the icon.
3. **Timer button made a bit bigger** (13px + more padding vs. the other status buttons' 11px)
   without changing its shape/border language. Re-verified the full chain end-to-end (start →
   stop → elapsed-time confirm dialog, pre-filled and averaged in → label-print-quantity
   prompt) — still wired correctly after everything else changed today.
4. **Found the real cause of "have to zoom out to reach Home"**: several input/select elements
   (`.prep-input`, `.form-field`, `.qa-qty-input`, `.qa-priority`) had `font-size` below 16px —
   iOS Safari auto-zooms the whole page on focusing any input under 16px and never zooms back
   out on its own. Bumped all of them to 16px (including a `max-width:420px` override that was
   making it worse, at 12px, on narrower phones specifically). This was a real, page-wide bug,
   not just cosmetic — fixes it everywhere these classes are used, not only Check List.

## Order List top bar: Print, Select/bulk-delete, Group by section (2026-07-12)

New toolbar row above the Order List summary, five buttons:

1. **🖨️ Print — real.** Builds a plain print sheet (grouped by section, name/qty/unit/notes)
   into a hidden `#orderListPrintSheet`, then reuses the same `body.printing-<mode>` +
   `visibility:hidden/visible` + `window.print()` + `afterprint` cleanup pattern already
   established for Print Labels.
2. **📤 Send to supplier — explicit placeholder.** Shows "We are working on it." Real supplier
   integration is intentionally deferred.
3. **☑️ Select — real.** Toggles select mode: every row grows a checkbox (reusing the existing
   `.qa-checkbox` component/colors), and a bulk-action bar appears with Select all / Clear
   selection / Delete selected. Built specifically so Richard can clear out a stale order list
   in a few taps instead of removing items one at a time.
4. **🗂️ By section — real, and now an explicit toggle** (was already the fixed default). Flips
   between the grouped-by-station view and a flat alphabetical list; the flat view tags each
   row with its section inline so nothing is lost by ungrouping.
5. **📱 By device — explicit placeholder.** Shows "We are working on it." — no per-device
   tracking exists yet on `order_list_items` to group by.

No new SQL — everything here works off the existing `order_list_items` table.

## Check List item Print icon + Print Labels hub toolbar (2026-07-12, later)

1. **🖨️ Print icon added to every Check List item row**, next to Order and the timer. Opens a
   new dialog (`printItemDialogOverlay`) shaped like the Order dialog but with two choices
   instead of a unit picker: **🖨️ Print now** (explicit placeholder — "We are working on it",
   this is where searching for an actual label printer will eventually live) and **🏷️ Add to
   print list** (real — queues the label with a quantity and a section, same device-local
   `_printQueue`/`localStorage` the timer-triggered flow already fed).
2. **Print queue entries now carry a section.** `addToPrintQueue(name, qty, station)` — dedup
   key is now name+station instead of just name, so the same item queued from two different
   sections stays as two separate rows. The post-timer prompt (`openPrintQuantityPrompt`) was
   updated to pass the item's section through too (`stationForItem()` looks it up via the
   item's dish), so every entry in the queue shows its section, not just the ones added from
   the new button.
3. **Print Labels hub got the same toolbar treatment as Order List:** 🖨️ Print (real — the
   existing native-print-dialog flow, now also reachable from the top bar; this is the same
   path that will grow into real label-printer discovery later), ☑️ Select (real, per-item
   checkboxes replace the +1/-1/Remove controls while active), **Select all** (real, its own
   top-level button — turns on select mode and selects everything in one tap), 🗂️ By section
   and 📱 By device (both explicit placeholders, "We are working on it" — every item's section
   is already visible in the row regardless, this toggle is about an alternate grouped view
   that isn't built yet).
4. Bulk delete: selecting items shows a "✕ Delete selected (N)" bar under the toolbar, for
   quickly clearing out stale queued labels — same pattern as Order List's Select mode.

No new SQL — the print queue stays device-local (`localStorage`), same as before.

## New feature: Working Time — check-in/check-out (2026-07-12)

New Home tile, first position: "⏱️ Working Time" — `db/39_working_time.sql`.

1. **Real check-in/check-out**, one open row per person in a new `time_entries` table
   (`check_out` null while on shift). Check In starts a live elapsed-time display
   (`workingTimeHoursForEntry`); Check Out closes the row. This is real Supabase data, not a
   device-local timer, since it's payroll-relevant and needs to survive a lost phone or a
   cleared browser.
2. **Break logging mid-shift**: four quick buttons (+5 / +10 / +15 / +30 min) add straight to
   the open entry's `break_minutes`, matching Richard's sketch. Break minutes are subtracted
   from worked hours when computing totals.
3. **Monthly summary, computed live**: days worked, total hours, and overtime — all summed
   from the 1st of the calendar month. Overtime is a fixed >8h/day threshold applied per
   calendar day (Richard's own rule: "ak človek pracuje viac ako osem hodín v daný deň"),
   independent of contracted hours. Matches his example format exactly: date, days worked,
   total hours, of which overtime — shown as three stat tiles.
4. **"Next day off" countdown**: a manually-set date on the profile (`next_vacation_date`),
   shown as days remaining. Deliberately NOT derived from the existing Schedule roster —
   `staff_members` rows there (18_schedule_v2_schema.sql) are just names a manager typed in,
   with no link to a real login account, so there's no reliable way today to match "whoever is
   logged in" to a specific roster row. A simple editable date ships today and works correctly;
   wiring the roster to real accounts is a separate, bigger project if it's ever needed.
5. **Contracted hours/week**: editable directly, OR set automatically by scanning a contract.
6. **Contract scan + AI advisory note**: reuses the exact same direct-to-Claude vision pipeline
   as the recipe and prep-sheet photo scans (same stored API key, same `scanOverlay` UI, same
   image-or-PDF support). Extracts contracted weekly hours and annual vacation days if stated,
   and writes a short plain-language note flagging anything unclear, missing, unusual, or
   potentially unfavorable to the employee (e.g. missing overtime terms, unclear notice
   period, below-typical vacation). Shown in a review sheet before saving, and explicitly
   labeled as informational commentary, not a substitute for a lawyer — this app has no
   business claiming to give real legal advice, and shouldn't imply otherwise.
7. **Not built yet, on purpose**: GPS geofencing to auto check-in/out near the workplace —
   Richard explicitly said this isn't needed today, just noted for later.

**New SQL to run:** `db/39_working_time.sql` — creates `time_entries` (RLS: each person only
ever sees their own rows) and adds `contracted_hours_per_week`, `next_vacation_date`,
`contract_notes` to `profiles`.

## Print Labels: shelf-life expiry dates + real label content, scan auto-translate (2026-07-12, later)

1. **Per-product shelf life, admin-locked.** New `print_label_settings` table (kitchen-wide,
   keyed by product name). The 🖨️ Print dialog on a Check List item now has a "Shelf life
   (days)" field: anyone can set it the first time; once set, only an admin ("hlavné
   zariadenie") can change it — enforced both in the UI (field disabled for non-admins once a
   value exists) and in RLS (defense in depth, not just a UI restriction).
2. **Labels now carry real content**, computed at the moment "Print" is actually pressed:
   product name (top), **use by** date (today's print date + that product's shelf life days,
   or "—" if no shelf life is set yet), **printed** date + time, and who requested it + which
   section. The name/date captured at "who requested it" time is whoever added the item to the
   print queue (`addToPrintQueue` now stamps `addedBy`/`addedAt`), matching what's shown in the
   queue list itself.
3. **Labels are now a real fixed physical size, 5x3cm** (`.label-block`), laid out in a
   flex-wrap grid on the print sheet instead of one full-width block per label — much closer to
   an actual label sheet. Typography sized down (8–12px) to fit all four lines legibly in that
   footprint.
4. **Bug fix while building this**: the new print-item dialog's `<select id="pd_station">` and
   `<input id="pd_qty">` (added last session) collided with pre-existing IDs of the same name
   already used by the "Add Dish" form (`showAddDishForm`/`savePrepDishForm`) — two completely
   unrelated forms silently reading/writing each other's fields via `getElementById`. Renamed
   the print dialog's fields to `pid_station`/`pid_qty` to fix it; verified no other ID
   collisions exist anywhere in the file.

## Scan auto-translate + settings (2026-07-12, later)

Recipe photo scans and prep-sheet photo/PDF scans now translate everything they extract into a
chosen language automatically — **on by default, English** — via one extra sentence appended
to each scan's existing prompt (`scanTranslateInstruction()`). A new 🌐 button in the Home
top bar (`openScanSettings`) lets it be turned off (keep original language) or switched to
German, Slovak, French, or Italian. Preference is per-user (`user_settings.scan_language`),
loaded alongside the existing Anthropic key. Contract scans are deliberately excluded from
auto-translation — translating a legal document changes its wording and could be misleading, so
that scan always reads the contract in its original language.

**New SQL to run:** `db/40_labels_shelf_life_and_scan_language.sql` — creates
`print_label_settings` and adds `scan_language` to `user_settings`.

## Working Time: Upload Schedule + real bar chart (2026-07-12, later)

1. **"📅 Upload schedule"** in Working Time settings — scans a real roster PDF/photo in the
   exact "Dienstplan Küchenteam" format already used by the Schedule feature (staff × date
   grid, shift codes like PJM/FR/FE/JTD). Reuses the same direct-to-Claude scan pipeline as the
   recipe/prep-sheet/contract scans.
2. **Name picker, not auto-matching.** After scanning, every staff row Claude found is listed
   and the person taps their own name. Deliberately not automatic: `profiles.full_name` isn't
   reliably filled in for anyone yet, so guessing by name match could silently save the wrong
   person's hours — a tap is one extra step but removes that risk entirely.
3. **Hours computed from the existing shift_codes dictionary**, not re-parsed from the PDF's
   own legend — the codes in this roster format are the exact same ones already seeded in
   `shift_codes` (18_schedule_v2_schema.sql) for the Schedule feature, so looking them up there
   (start/end time, split-shift second segment, break minutes, is_absence) is both less work
   and more reliable than asking Claude to re-derive hours from a legend table on the same
   page. New `shiftCodeHours()` helper computes net worked hours per code.
4. **New `schedule_forecast` table** (`db/41_schedule_forecast.sql`) — one row per user per
   date: shift code, computed hours, is_absence. RLS-scoped to each person's own rows only.
5. **Real bar chart, not a placeholder** — `renderWorkingTimeChart()`, plain CSS/flexbox (no
   charting library, nothing to fail to load), one bar per day across the current calendar
   month, horizontally scrollable. Bar source per day: actual worked hours from `time_entries`
   for days already checked in; otherwise scheduled hours from `schedule_forecast` (this is
   the only source for future days, since they haven't happened yet); a flat "day off" marker
   for absence codes; a hatched "no data" bar for any day with neither — e.g. days before the
   uploaded schedule's coverage started, matching Richard's own example (a schedule starting
   10.07.2026 shows "no data" for the 1st–9th rather than a misleading zero).
6. **Working Time's stats card is now sticky**, attached directly under the Home button in a
   `.wt-sticky-top` wrapper — always visible without scrolling, per Richard's request that it
   "fit into the top bar too." Same pattern as Check List's sticky summary bar earlier this
   session.

**New SQL to run:** `db/41_schedule_forecast.sql`.

## Fix: Upload Schedule failing on a real multi-page roster (2026-07-12, later)

Root cause found after Richard tried scanning his actual 3-page Dienstplan PDF and it just
failed: the scan asked Claude to transcribe the **entire roster** in one response — his real
file has ~30 staff × 21 date columns, 600+ day-entries, which blew past the response's
`max_tokens` and made Claude return no usable `tool_use` block at all (surfaced as "Claude
could not read this schedule").

Fixed by asking for one person's row instead of everyone's: "Upload schedule" now first asks
the person to type/confirm their name (`scheduleNameConfirmOverlay`, pre-filled with their
profile name), then the scan prompt asks Claude to find and transcribe *only* that one row
across every page — ~20-30 day-entries instead of 600+, comfortably inside the token budget.
After a match is found, a quick confirm ("Found schedule for X — save it?") guards against a
wrong fuzzy match before anything is written. The old "pick your name from a list of everyone
found" flow is gone — it depended on successfully extracting the whole roster in the first
place, which was the actual bug.

## Contract AI note: collapsible + individually checkable points (2026-07-12, later)

Richard confirmed the contract scan works well, but the note sat permanently open under the
Upload button, and was one wall of text with no way to track which concerns had actually been
sorted out.

1. **Collapsible.** Wrapped in the same `<details class="more-details">` disclosure widget
   already used for the recipe form's "More details" section — native, no extra JS, closed by
   default. A small `_contractNotesOpen` flag keeps it open across re-renders while checking
   points off (otherwise every checkbox tap would re-render the section closed again).
2. **Individually checkable points.** The scan's tool schema changed from one `advisory_notes`
   paragraph to an `advisory_points` array — Claude now returns a list of short, single-issue
   points instead of a blob of prose. Each renders with its own checkbox (`.wt-check-btn`);
   tapping it flips a green check and strikes through the text, persisted to the new
   `profiles.contract_advisory_points` (jsonb array of `{text, done}`).
3. **Backward compatible.** The old `contract_notes` column (Richard's already-completed scan)
   still displays as plain text inside the same collapsible section — just without checkboxes,
   with a note to re-scan for the new checkable format.

**New SQL to run:** `db/42_contract_advisory_points.sql` — adds `contract_advisory_points`
(jsonb) to `profiles`.

## Working Time: compact tappable summary + monthly pie-chart history (2026-07-12, later)

1. **Sticky summary card is now ~50% smaller** (`#workingTimeSummaryCard` overrides on the
   shared `.wt-card`/`.wt-stat` classes — smaller padding, 22px→14px stat numbers, 10.5px→8px
   labels) and tappable — a "Charts ›" hint sits next to the date.
2. **New "Hours by Month" view** (`workingTimeChartsView`), opened by tapping that card: one
   pie chart per month of a chosen year, pure CSS `conic-gradient` circles (no charting
   library, nothing to fail to load), each split into regular hours vs. overtime for that
   month. A year switcher (‹ / ›) lets Richard page back through history — computed fresh from
   `time_entries` for whichever year is selected, not just the current month. Deliberately
   sourced only from real `time_entries` (never `schedule_forecast`) since this view is
   specifically "odrobené hodiny" — hours actually worked, not scheduled.
3. **Weekday initials everywhere a day-by-day breakdown is shown** — the existing month bar
   chart on the main Working Time page now shows the first letter of the Slovak weekday
   (Po/Ut/St/Št/Pi/So/Ne → P/U/S/Š/P/S/N) above each day number (`WEEKDAY_INITIALS_SK`). The
   new monthly pie-chart view is month-level, not day-level, so this doesn't apply there — no
   per-day breakdown exists on that screen to label.

No new SQL — both features compute entirely from the existing `time_entries` table.

## Home: bigger icons + reorder, Working Time: richer "next day off" (2026-07-12, later)

1. **Home tile icons made as large as the square allows.** 20px→34px font-size, 34px→48px
   icon box, tile padding trimmed slightly (10px→8px) to make room — the label still fits
   underneath without overflowing.
2. **Reorder Home icons.** New 🔀 button in Home's top bar opens a list with ▲/▼ per row
   instead of drag-and-drop (more reliable on touch without pulling in a drag library). The
   Home grid is now rendered from a JS list (`HOME_TILE_DEFS`) instead of static HTML, so order
   — and the admin-only tile's visibility — can change at runtime. Order is saved to
   `localStorage` (`chefos_home_tile_order`) as a **device-local personal preference**, not
   synced kitchen-wide, since how one person likes their own home screen arranged has nothing
   to do with anyone else's phone.
3. **"Next day off" now shows weekday + date + countdown together** instead of just a bare day
   count — e.g. "Streda · 16.7.2026" with "4 days left" underneath, using `toLocaleDateString`
   with Slovak weekday names.

No new SQL — the tile order lives in localStorage, and the next-day-off change is
display-only.

## Remove Schedule from Home, shift reminder notification (2026-07-12, later)

1. **Schedule tile removed from Home** — Richard's call: it's redundant now that Working Time
   covers what he needs day-to-day (the bar chart + Upload Schedule). The Schedule feature
   itself (`showSchedule()`, the staff×date grid, `shift_codes`/`schedule_assignments`) is
   untouched and still fully working — just dropped from `HOME_TILE_DEFS`, not deleted, in case
   it's needed again later (also still used internally: Working Time's shift-hours calculation
   reads the same `shift_codes` table).
2. **Shift reminder — real browser Notification, 45 minutes before a scheduled shift**, opt-in
   toggle in Working Time settings. Checks today's `schedule_forecast` row every 60s, looks up
   that shift code's start time in `shift_codes`, and fires once when 45 minutes out (a
   `localStorage` flag per date stops it firing repeatedly). Requests `Notification` permission
   on first enable, from the toggle tap itself (a real user gesture, required by browsers).
   **Important, disclosed to Richard directly**: this only works while ChefOS is open in the
   browser (foreground, or a backgrounded tab the OS hasn't killed) — there's no server
   component in this app to wake a fully closed phone/tab. True background push would need Web
   Push + a server-side scheduler (e.g. a Supabase Edge Function on a cron), a separate, larger
   build — noted as a future upgrade if this foreground version isn't enough in practice.

No new SQL — reminder state is a localStorage flag; the shift-time lookup reuses
`schedule_forecast` + `shift_codes`, both already in place.

## Test data for Hours by Month, contract checkbox migration fix (2026-07-12, later)

1. **`db/43_seed_test_hours.sql`** — not a schema migration, a one-off script Richard can run
   to fill his own account with ~5 months of randomized past `time_entries` (random times,
   some days pushing past 8h so the overtime slice actually renders), purely so "Hours by
   Month" has something to look at. Includes the one-line delete to remove it again afterward.
2. **Fixed: contract AI note still showing as plain text, no checkboxes.** Root cause: points
   only ever got created going *forward*, at scan-save time — a contract already scanned before
   that existed just sat as the old plain-text `contract_notes` forever, since nothing ever
   converted it. `migrateContractNotesToPoints()` now runs automatically on every Working Time
   load: if `contract_advisory_points` is still empty but `contract_notes` has text, it splits
   the note into individual points (on blank lines / sentence breaks, falling back to the whole
   note as one point if splitting finds nothing) and saves it as real checkable points —
   one-time, silent, no re-scan required.

## Fix: Check List summary bar wrapping on a long section name (2026-07-12, later)

Richard sent a screenshot of a long section name ("Olív restaurant & bar 2.trial") breaking the
sticky summary bar: 👁️ Visibility landed on its own ragged left-aligned line, and the time-
remaining pill wrapped onto a *third* line, pinned to the right by its old `margin-left:auto`
— three uneven lines instead of a clean layout.

Fixed by grouping section name + Visibility + time-remaining into their own row
(`.prep-summary-row2`, forced onto a new line below the to-do/check/finish/don't-do chips via
`flex-basis:100%`), with Visibility and the time pill further wrapped together in
`.prep-summary-meta` so they can never split from each other. That row is
`justify-content:center`, so whenever the name is too long for everything to fit on one line,
Visibility+time wrap as a single centered unit directly underneath — matching Richard's ask
exactly. Applies everywhere this summary bar is used (every station and "All"), since they all
share the same `renderPrepSummaryBar()`.

## Check List: sync repeated items kitchen-wide (2026-07-12, later)

Richard's example: "Housedressing" appears as its own row under several different dishes —
sometimes in different stations. Marking it TO DO / on-hand 1 / priority 1 in one place should
show the same everywhere else that name appears in the kitchen, since it's the same real thing
either way, not a coincidence of naming.

`updatePrepItem()` now calls `syncPrepItemAcrossKitchen()` after every status/on_hand/priority
change: it finds every other (non-deleted) `prep_items` row across the whole kitchen — any dish,
any station, matched by name (case-insensitive, trimmed) — and applies the same value to all of
them, both in the already-loaded `_prepItems` list (instant UI update everywhere) and in
Supabase (one batched `.update().in('id', ...)`). Deliberately scoped to status/on_hand/priority
only, not notes — a note is legitimately specific to one dish's context (e.g. "extra for the VIP
table") and forcing it to match everywhere would be wrong.

This replaces the older "dedup identical items" backlog idea with something better: items stay
as separate rows (still correctly attached to their own dish's composition), but their real-world
prep status stays in sync automatically instead of needing a data-model merge.

No new SQL — this works off the existing `prep_items.kitchen_id` column, already in place.

## In-app sample data for Hours by Month (2026-07-12, later)

Richard tried the raw-SQL seed script (`db/43_seed_test_hours.sql`) but still saw "No data"
Jan–Jun — running SQL directly in Supabase turned out to be more friction than it was worth for
a one-off preview. Replaced with a **🎲 "Add sample data for this year (test only)" button**
directly in the Hours by Month view: `generateSampleWorkingHours()` writes randomized Jan–Jun
`time_entries` straight into his own account through the same authenticated Supabase client the
rest of the app already uses (RLS already scopes it to rows he owns) — one tap, no SQL editor
needed. Clearly labeled as test-only in the button text itself.

## Check List: on-hand/priority/time always on one row, sync notes, "also appears elsewhere" warning (2026-07-12, later)

Two screenshots from Richard: a long item/dish name was pushing ON HAND onto one line and
PRIORITY + the time badge onto ragged separate lines below it.

1. **On-hand, priority, and the per-task time badge now live on their own dedicated row**
   (`.prep-line1b`, `flex-wrap:nowrap` with horizontal-scroll as a safety valve) directly under
   the item name, instead of being crammed into the same wrapping row as the name. They now
   always stay together on one line regardless of how long the name (+ dish suffix) is.
2. **Notes now sync too**, not just status/on-hand/priority — added to
   `PREP_ITEM_SYNCED_FIELDS`. Richard's explicit follow-up: "ako hovorím aj notes."
3. **New "also appears elsewhere" warning badge** (`.prep-duplicate-badge`, gold/amber —
   deliberately loud per Richard's "do očí bijúca výstraha," but gold rather than red since it's
   informational, not a danger signal). Shown on any checked item (status ≠ don't-do) that has
   the same name as another item somewhere else in the kitchen. Tapping it opens a sheet listing
   every other section + dish name that ingredient is also tracked under
   (`findDuplicatePrepItemOccurrences()` / `openDuplicateItemInfo()`).

Not changed: Order List behavior — Richard mentioned "notes a orders" but didn't specify a
concrete change there beyond notes syncing; worth a follow-up if he had something specific in
mind for Order List itself.

No new SQL — all three are UI/logic changes over existing `prep_items` columns.

## Eight-part batch: Working Time drill-downs, day notes, section fixes, search, cleanup (2026-07-12, later)

1. **Hours by Month pies are now clickable.** Tapping any month opens a day-by-day bar chart
   for that month (`openMonthDayBars()`), same visual language as the main Working Time bar
   chart — sourced from the year's already-loaded `_wtChartsYearEntries`, no extra query.
2. **"This month" history rows are now clickable**, and the main bar chart's day columns too —
   all three entry points (This month list, main chart, month drill-down) open the same day
   detail sheet (`openDayDetail()`).
3. **New feature: per-day notes with an optional photo.** New table
   `working_time_day_notes` (`db/44_working_time_day_notes.sql`, one row per user per date,
   auto-saves on the note textarea's blur) plus a new public Storage bucket
   `working-time-notes` for the photo (camera-or-gallery picker via
   `<input type="file" accept="image/*" capture="environment">`, uploaded to
   `<user_id>/<date>.<ext>`, RLS-scoped to the owning user for writes). Days that already have a
   note/photo get a small 📝 marker in the "This month" list.
4. **New section creation now lands directly in the empty new section** instead of immediately
   forcing the "Add Dish" form — `createNewStationAndOpenDishForm()` now calls
   `renderActiveStationView()` instead of `showAddDishForm()`.
5. **New search FAB** (magnifying glass, left of the existing add FAB) — search any ingredient
   by name across the whole kitchen; 3+ characters shows up to 5 best matches (starts-with
   beats contains-only, then shortest name wins ties), tapping one jumps straight to that
   item's section.
6. **Order/Print dialogs no longer show a station dropdown.** It was populated from the old
   fixed `DEFAULT_STATIONS` list and silently couldn't offer a custom-created section at all —
   removed entirely; both dialogs now always use whichever section you were actually in when
   you tapped Order/Print.
7. **"Clear queue" renamed to "Clear list"** everywhere (button, confirm dialog, "Add to Print
   Queue" → "Add to Print List"). Also: Richard found Print All / Clear List not working on one
   of his 3 test devices, traced to the browser — [Firefox Klar](https://apps.apple.com/ch/app/firefox-klar/id1073435754),
   a privacy-focused browser that blocks trackers/scripts aggressively by default. Not a ChefOS
   bug; noting it here as a known incompatibility in case it comes up again — Klar's tracking
   protection can interfere with `window.print()`/localStorage-heavy flows. No fix needed on
   our side unless it turns out to affect a mainstream browser too.
8. **Audited the timer → averaging chain** end-to-end (start/stop timestamp math, the
   `openAddTimeForItem`/`saveAddTimeForItem` averaging formula, per-stage `*_minutes`/
   `*_minutes_n` fields) — no bugs found, logic is correct as originally built.

**New SQL to run:** `db/44_working_time_day_notes.sql` — creates `working_time_day_notes` and
the `working-time-notes` storage bucket with its policies.

## Check List: manage/delete sections from one place (2026-07-12, later)

A "Delete this whole section" button already existed, but only at the bottom of that section's
own dish list — one section at a time, and only after scrolling past everything in it. New
**🗑️ Manage / Delete Sections** button in the "Check List — Sections" picker opens a dedicated
list of every section with its own Delete button, so any section can be removed without first
navigating into it. Reuses the exact same `deleteStation()` underneath — soft-delete, fully
recoverable afterwards from "N deleted" inside that section — nothing new on the data side.

No new SQL — UI-only, built entirely on the existing soft-delete mechanism.

## Recipes list restyled to match Check List (2026-07-12, later)

Richard: Check List's design is "the way I imagined" now — wants Recipes brought into the same
visual language rather than the two screens looking like different apps. Scoped to the Recipes
**list** (the browsing screen, most comparable to Check List's item list) for this pass:

1. **Sticky header.** Topbar + search + category chips now live inside `.sticky-header` (the
   same wrapper Check List uses), so the category filter stays reachable while scrolling
   instead of scrolling away — it only used to be the very top title bar that stayed pinned.
2. **Recipe rows now match `.prep-item-row`'s exact treatment**: monospace font
   (`"SF Mono", Menlo`), the same soft sage background wash (`rgba(150,165,134,0.12)`), a top
   divider instead of a bottom one, and the title in bold sage (`var(--sage)`) instead of plain
   `--ink` — same recipe (no pun intended) as every Check List item row, just applied to
   `.recipe-row`.

Not touched yet: the recipe **detail** and **edit form** screens — very different content
(hero image, ingredients table, method steps, nutrition) that doesn't map cleanly onto
Check List's card language. Worth a separate pass if Richard wants those unified too.

No new SQL — CSS/HTML only.

## Recipes navigation now mirrors Check List's section picker exactly (2026-07-12, later)

Richard's follow-up: "tak isto ako v check liste" (the same as in Check List) — Recipes'
category browsing now works identically to how Check List's stations work, not just visually.

1. **Opening Recipes now always shows Favorites**, not "All" — `showList()` resets
   `activeCategory` to `'Favorites'` on every open, deliberately not remembered between visits.
   Favorites is now a real section value (like Check List's `'All'`), not a separate toggle
   layered on top of a category.
2. **Every other section (All, Soups, Sushi, Meat, Dressings, …) moved behind a ☰ icon**, right
   next to Home in the sticky header — opens "Recipes — Sections", the same tile-grid picker
   sheet Check List uses (`recipeCategoryPickerOverlay`, mirrors `stationPickerOverlay`), each
   tile with its own icon and a live recipe count. A dashed "➕ New Section" tile creates a new
   category with an icon (`newRecipeCategoryOverlay`, same icon-choice grid and flow as Check
   List's "New Section").
3. **New "🗑️ Manage / Delete Sections"** inside that picker, listing every category with a
   Delete button — but deleting here **recategorizes its recipes to "Uncategorized" instead of
   deleting anything**. Deliberately not a soft-delete like Check List's `deleteStation()`: a
   recipe is real, hard-to-recreate content, not a disposable prep task, so this stays fully
   non-destructive by design.
4. **New "👁️ Visibility"** button next to the section name in the sticky summary row (same
   `.prep-summary-row2`/`.prep-item-clock` styling as Check List) — device-local show/hide per
   category tile, same mechanics as Check List's Section Visibility (`localStorage`, doesn't
   touch any data).
5. Category icons: reused `STATION_ICON_CHOICES` (the same curated gastro emoji set from Check
   List) for the picker, plus sensible defaults for the categories already in use (Soups 🍲,
   Desserts 🍰, Meat & Mains 🥩, Sushi 🍣, etc.) so nothing looks unset before anyone picks
   anything — matches Richard's "ikonu... teraz to nie je dôležité."

**New SQL to run:** `db/45_recipe_category_icons.sql` — creates `recipe_category_icons`
(kitchen-wide, same shape as `station_icons`).

## Critical fix: whole app broken by a script-order bug, plus Check List title (2026-07-12, later)

Richard reported Recipes looked empty (see previous entry — turned out to be the new
Favorites-by-default landing on nobody having favorited anything yet), then reported Check List
itself stopped working. The second one was real and serious.

**Root cause**: the previous batch added `let _newRecipeCategoryIcon = STATION_ICON_CHOICES[0];`
as a *top-level* statement, positioned in the file *before* `STATION_ICON_CHOICES` itself gets
declared (`const`, ~1200 lines later). Reading a `const`/`let` before its declaration line has
run throws `ReferenceError: Cannot access 'STATION_ICON_CHOICES' before initialization` — and
since this is all one inline `<script>` block executed top-to-bottom, that uncaught error
stopped the *rest of the script's top-level execution* right there. Every `function` declaration
was still defined (those hoist fully regardless), but any top-level setup code positioned after
that line never ran on page load — which is why Check List broke while other things kept
working.

**Fix**: `_newRecipeCategoryIcon` now starts as plain `null`; the real value
(`STATION_ICON_CHOICES[0]`) is still assigned exactly where it always was, inside
`openNewRecipeCategoryPrompt()` — which only ever runs after a user taps something, by which
point the whole script has finished loading and `STATION_ICON_CHOICES` is long since defined.
Audited every other top-level `let`/`const` added this session for the same shape of bug
(initializer referencing another module-level name) — nothing else found.

**Also fixed**: Check List had no title at all in its sticky header (removed earlier this
session to keep the header compact) — now that Recipes/Working Time show one, its absence read
as "broken" rather than "intentionally minimal." Added a small `.kicker`-style "📋 Check List"
line (~17px tall, not a full `<h1>`) so there's a title without reintroducing the height problem
Richard was explicit about earlier ("must always stay pinned," repeated three times in one
sitting last week).

No new SQL — both fixes are JS/CSS only.

## Ingredient audit, Newest-first, search/diet filters, wider category icons (2026-07-12, later)

Five-part batch, resuming the request that got interrupted by the two bugs above. Given what
just happened, every new top-level declaration in this batch was deliberately kept to safe
literal initializers (or moved inside a function body) and the whole file was re-audited for
the same script-order bug afterward — see verification note at the end.

1. **Recipe double-save — reconfirmed, not a bug.** `saveForm()`'s `_savingRecipeForm` guard is
   still intact and still the only call site wired to the Save button. No duplication happens.
2. **New Ingredient Audit tool** (🔍 icon in the Ingredients screen's top bar,
   `runIngredientAudit()`) — read-only scan across every recipe's ingredient-table rows and
   every Check List item name, normalized the same way the existing ingredient-matching system
   already does (`normalizeIngredientText`/`_ingredientLookup`), reporting: (a) names with no
   matching row in Ingredients at all, with a "Create all N" bulk-insert button (new rows
   default to unit "kg", price blank — flagged in the confirm dialog that units need fixing
   per item), and (b) ingredients-table rows that normalize to the same name (a real duplicate
   check, not just exact-string, so "Tomato"/"Tomatoes" get caught) — reported for manual
   review only, nothing is ever auto-merged or deleted.
3. **🕐 Newest button**, same summary row as the section name/Favorites, next to Visibility.
   Switches to a flat, ungrouped, all-recipes list sorted by `created_at` descending — required
   adding `createdAt` to `dbRowToRecipe()`'s mapping, which wasn't there before.
4. **Search rebuilt as a standalone icon + filter sheet.** The always-visible search bar is
   gone; a 🔍 icon next to ☰ opens "Search & Filter" with: the text search box, a section
   dropdown (same options as the picker), Vegetarian/Vegan toggles, and a "Free from" chip grid
   covering every `ALLERGEN_MAP` category (Gluten, Dairy, Tree Nuts, etc.). Vegetarian/vegan
   detection is a new heuristic (`computeDietTags()`) — no recipe has ever been manually tagged
   for this, so it re-uses the Fish/Crustaceans/Molluscs/Dairy/Egg keyword lists already built
   for allergen detection, plus a new `MEAT_KEYWORDS` list, and is explicitly labeled in the UI
   as a best-effort guess, not a verified fact. A small dot on the 🔍 icon shows when any
   search/filter is currently active. Settings apply on "Apply," matching every other sheet in
   the app rather than live-filtering per keystroke.
5. **Category icons reviewed and expanded.** `RECIPE_CATEGORY_ICON_FALLBACKS` grew from 9 to
   ~35 entries (Poultry, Fish & Seafood, Pasta & Rice, Breakfast, Cocktails, Charcuterie, etc.)
   so more real category names get a sensible icon instead of falling through to 🍽️. New
   `RECIPE_ICON_CHOICES` for the "create new section" picker — Station's original 30 plus ~30
   more food-specific ones (seafood, fruit/veg, sweets, drinks) that fit a recipe *category*
   better than a kitchen *station* tile.

**Verification, given the last batch broke the app**: re-ran the full structural check (braces,
divs, buttons, every `onclick`/`onchange` handler resolves, every `getElementById` target
exists) and, specifically, re-scanned every top-level `let`/`const` added in this batch for the
same "references a name declared later in the file" bug — including catching one *before* it
shipped this time: `#search`'s old `addEventListener` binding, left over from the search bar
that no longer exists, would have thrown the identical class of error on every page load if
removing the search bar had left it in place. Removed it.

**New SQL to run:** none — everything in this batch works off already-loaded data.

## Real supplier ingredient prices from Caviezel Giovanettoni AG price list (2026-07-12)

Richard uploaded 4 supplier PDFs to `Supliers price lists/`. Two were just website-navigation
printouts with no actual price data (`caviezel giovanettoni ag.pdf`, `Katalog und Preisliste.pdf`).
`Sortiment.pdf` (Swiss Gastro Solutions, 5 pages) was read in full but every one of its ~19
products is a branded finished snack (Mini-Schinkengipfeli, Apéro-Chüechli, etc.) — out of
scope, contributed nothing. `preisliste-brutto-2026-komplett.pdf` (92 pages, Caviezel
Giovanettoni AG's full 2026 gross price list, thousands of SKUs) was the real source — its text
layer was extracted directly (via `pypdf`, since this environment has no `pdftoppm`/poppler for
page-image rendering) and handed to a background agent with strict scoping rules.

**New file: `db/46_supplier_ingredients.sql`** — 104 `insert ... on conflict (kitchen_id,
lower(name)) do update set price/price_currency/notes` rows. About 50 are brand-new
ingredients; ~54 upgrade an existing *estimated* price to this *real, sourced* Swiss wholesale
price (every row's `notes` cites the catalog article number for traceability). Categories:
Fruit, Vegetable (incl. wild mushrooms), Seafood, Dairy, Eggs, Sauces & Condiments, Oils &
Vinegars, Chocolate & Cocoa, Dry Goods, Grains & Flour, Bakery.

Deliberately excluded: the thousands of branded/prepared SKUs in the catalog (McCain, JOWA,
HUG, Frigemo, Kern & Sammet, Bina, frozen pastries, ready meals, ice cream, canned goods) — a
recipe ingredient line should say "onion," not a specific frozen brand's product code. Also
dropped Kiwi/Orange/Melon/Pineapple even though the catalog prices them, because those prices
were sourced from a pre-cut fruit-salad SKU (reflects prep labor, not raw fruit cost) — using
them would have quietly mispriced those existing ingredients.

**Currency note:** source prices are CHF; the existing 535-row ingredients table is entirely
`price_currency='EUR'` (matches the UI, which hardcodes a "€" symbol regardless of the stored
currency). Converted at a rough 1 CHF ≈ 1.06 EUR, disclosed in a comment at the top of the SQL
file and implicitly in the fact these are not live rates.

**Still needed from Richard:** run `db/46_supplier_ingredients.sql` in Supabase. Separately —
his "add all missing ingredients used in recipes/Check List" request is already built as the
in-app 🔍 Ingredient Audit tool (Ingredients screen top bar → runs `runIngredientAudit()` →
"Create all N missing ingredients" button) from the previous batch; this PDF work is a
complementary price-enrichment pass, not a substitute for tapping that button himself, since
there's no live database access from here to run the scan directly.

## Six-part batch: rename/icon on sections, diet filter fixes, AI recipe assistant, ingredient audit rebuild, currency switcher, Ingredients redesign (2026-07-12)

1. **Rename + change icon** added to both Check List's Manage Sections and Recipes' Manage
   Categories (previously delete-only). Renaming moves every real row over (`prep_dishes.station`
   / `recipes.category`, both plain text fields) and re-points the kitchen-wide icon row
   (`station_icons` / `recipe_category_icons`) — in-memory `PREP_SHEET_STATIONS`/
   `DEFAULT_STATIONS`/`CUSTOM_RECIPE_CATEGORIES` arrays are spliced in place so the old name
   doesn't linger as a stale second entry until the next reload.
2. **Diet filter highlight bug fixed** — Vegetarian/Vegan toggles were already tracking state
   correctly, they just used `.task-status-btn`'s barely-visible `opacity:0.85→1` active style
   instead of the much more visible `.chip.active` copper highlight already used for allergen
   "Free from" chips. Switched to the same `.chip` styling. Also expanded from 2 to 7 diet
   chips — added Pescatarian, Keto, Paleo, Mediterranean, High-Protein, each a new best-effort
   keyword heuristic in `computeDietTags()`, same disclosed-as-a-guess treatment as vegetarian/
   vegan.
3. **Recipe search now always searches everything by default** — opening the search sheet used
   to preselect whatever category tab was currently open (so searching from Favorites silently
   only searched favorites); now always defaults to "All", with the section dropdown still
   available to narrow it back down deliberately.
4. **"🤖 Ask Chef's Assistant"** — new button in the recipe search sheet. Asks two quick
   questions (warm/cold, sweet/savory), then calls Claude for 5 real dish ideas matching those
   answers plus whatever search text/diet/allergen filters are staged, then writes out the full
   recipe for whichever one is picked. Always lands on the normal edit-recipe form for review —
   nothing is ever written to the database automatically, same principle as the existing
   photo-scan import flow (in fact reuses its exact landing mechanism, `renderForm()`).
5. **Ingredient Audit rebuilt into a real per-item approval flow (Phase A).** The old tool had
   one "Create all N missing" bulk button — a real problem in practice, since many Check List
   item names carry their quantity inline (e.g. "Cukor 2kg"), so bulk-creating was producing
   duplicate/garbage rows for ingredients that already existed under a cleaner name. Every
   candidate is now its own card: an editable name (pre-cleaned of leading/trailing qty+unit
   text via `cleanIngredientCandidateName()` as a starting suggestion, not a final answer), a
   unit/category to set, and three real actions that each act immediately — ✅ Add as new,
   🔗 Link as an alias of an existing ingredient (picked from a dropdown), or ✕ Ignore.
   **Phase B (not this batch):** hook this same normalize+match check into every ingredient-
   entry point live — manual dish add, AI photo scan, file upload — so an unrecognized name
   triggers the same approval prompt at creation time, before it's ever saved as loose text.
   This is what actually stops the backlog from building back up; Phase A only cleans up what
   already exists today. Next up whenever Richard wants it.
6. **Kitchen-wide currency switcher** — new admin-only Home tile (💱 Currency). Prices stay
   stored in EUR everywhere (matches all existing ingredient rows and every cost calculation);
   the switcher only changes how they're *displayed*, for the whole team at once, via a fixed
   approximate rate (`CURRENCY_INFO` in `app/index.html`) — not a live exchange rate. Every
   hardcoded "€" in the app (recipe cost block, cost breakdown, ingredient list price, ingredient
   info panel) now goes through `formatMoney()` instead. The ingredient add/edit form's price
   field is also currency-aware now — typed in whatever the kitchen's current display currency
   is, converted back to EUR on save, so data entry doesn't require mentally converting.
   **New SQL: `db/47_kitchen_currency.sql`** — adds `kitchens.display_currency` with
   `default 'CHF'`, which backfills the existing pilot kitchen to CHF immediately (Richard: the
   kitchen operates in Switzerland and the investor presentation is being done in CHF too).
7. **Ingredients screen topbar redesign** — the always-visible search box plus four separate
   filter chip rows (category/season/storage/food-type) were permanently pinned across the top,
   eating a large chunk of the screen before any scrolling. Moved all of it — search input, all
   four chip rows, and the Ingredient Audit trigger — behind one 🔍 icon button in the topbar
   (`#ingredientFiltersOverlay`), same icon size and sheet pattern as Check List's ☰ and
   Recipes' 🔍. Chip click behavior is unchanged (still filters live, sheet just stays open); only
   where they physically live moved.

**Verification**: full structural check (braces/divs/buttons/selects balanced, every `onclick`/
`onchange`/`oninput` handler resolves to a defined function, every `getElementById` target exists
— only the two known dynamic-id false positives, `adminPendingBadge`/`printLabelsBadge`, remain
unmatched, as always) plus a full top-level `let`/`const` declaration-order re-scan for the TDZ
bug class from the two July 12 incidents earlier this session — nothing new found.

## Ingredients search-button polish, four small fixes, logo, and two research reports (2026-07-13)

**Ingredients search/filter follow-up** (Richard: "nič ma nenapada ale pride mi že to može byť
lepšie" — polish request, no concrete spec given): the 🔍 icon in Ingredients was icon-only with
no visible label — added a text label "Search & Filter" next to it. Also caught and fixed a real
mislabeling bug: the cuisine chips (European/Asian/Universal) were headed "Category" in the sheet
I built the previous batch, which is wrong — that's the `cuisine` field; the actual `category`
field is the separate "Food type" chip row. Relabeled to "Cuisine", reordered Cuisine + Food type
above the less-used Season/Storage rows, and added a "Clear all" button (previously the only way
to reset all 4 filters + search was clicking "All" on each row individually).

**Four small fixes:**
1. **Working Time day-note text was invisible while typing.** Root cause: the page never
   declared `color-scheme: dark`, so on some mobile browsers a `<textarea>` renders with the
   OS's own light-mode native chrome layered under the page's dark CSS — dark text color
   inherited, light background underneath, invisible. Added `color-scheme: dark` globally
   (fixes this class of bug for every form control, not just this one field) plus an explicit
   `appearance:none` + `-webkit-text-fill-color` on `textarea.form-field` as a second layer of
   defense specific to textareas (which carry more native chrome than plain inputs).
2. **Home screen tile icons enlarged again** (icon box 48px→62px, font-size 34px→44px) — still
   3 tiles per row, per Richard's explicit ask to keep that layout.
3. **Print Labels** was the only screen missing a topbar title — added `<h1>Print Labels</h1>`
   (marked `no-print` so it doesn't leak into the actual label print sheet). The "🗂️ By section"
   button was a `printLabelsNotImplemented()` placeholder — wired it up for real, mirroring Order
   List's `toggleOrderListGrouping()` pattern exactly (groups the print queue by `station`, with
   a "No section" bucket for manually-typed labels that never got one).
4. **Minimalist ChefOS logo** — a simple circular monogram (white circle, copper ring, copper
   "C") kept deliberately plain so it stays legible at the tiny size it needs to sit at.
   `chefOSLogoMarkSvg(size)` renders it inline as SVG (no image asset). Applied it live in two
   places on the My Team screen: a small brand header, and centered on top of the invite QR
   code itself — bumped the QR's error-correction level from 'M' to 'H' since the logo now
   covers real modules and needs the extra correction headroom to keep scanning reliably.

**Two research reports** (background agents, web search — Richard asked for a printer
recommendation and a fridge-temperature-sensor recommendation; he mentioned having his own
printer document to review but it wasn't found anywhere in this session, so this is independent
research to hand him a starting point, not a review of his actual document):

- **Label printer** (`docs/LABEL_PRINTER_RESEARCH.md`): recommends the **Brother QL-820NWB**
  (~CHF 130), bought outright with no contract, printed to via the exact same `window.print()`
  flow the app already uses — no code changes needed. No small-format printer has a genuine
  zero-install cross-browser web print API (Zebra/Brother/DYMO all require a locally-installed
  agent); that tier of integration isn't worth it yet for one pilot kitchen.
- **Fridge temperature sensor**: the literal "scan a QR, get a live reading" idea needs a
  WiFi/cloud-API sensor, not a cheap Bluetooth one — Web Bluetooth and Web NFC are both
  unsupported in iOS Safari entirely, and staff will mostly be on iPhones. Recommended
  **SensorPush** (~CHF 150/fridge including its WiFi gateway) as the only budget option found
  with a real, free, publicly documented cloud API a web backend could actually call.

**First named sales target**: Richard designated **Nooch Asian Kitchen** (FWG restaurant group)
as the first customer to approach once the pilot validates the product — confirmed via web
search as a real 10+-location Swiss chain, with 3 locations already in canton Bern
(Aarbergergasse, Viktoriaplatz, Westside), directly matching the existing canton-Bern-first
go-to-market strategy. No contact made yet — a target identification, not an active deal.

**Verification**: same full structural pass as every batch this session (braces/divs/buttons
balanced, every handler/id resolves, top-level declaration-order re-scanned for the TDZ bug
class) — nothing new found. No live browser testing was possible from this environment (no
access to Richard's device or a way to log into the running app); flagged as usual.

## Ingredients filter sheet: live match count, real category list, pricing-status filter (2026-07-13, later)

Richard's follow-up on the earlier polish pass: he wanted the count of matching ingredients
visible *while* adjusting filters, not just after closing the sheet — and clarified "vylepši to"
from the previous turn meant something more creative than the mislabel fix, specifically calling
out that categories like Alcohol/Bakery are only ever visible as section-label headers while
scrolling the full list, with no way to filter straight to them, plus asked for one more
genuinely useful new filter, left to my judgment.

1. **Live "N ingredients match" count** — new `#ingredientFilterCount` line under the search box
   inside `#ingredientFiltersOverlay`, recomputed via `updateIngredientFilterCount()` on every
   chip tap and every search keystroke. Extracted the shared filter predicate into
   `passesIngredientFilters(ing, q)` (used by both the count and `renderIngredientList()` itself)
   instead of leaving the logic duplicated in two places.
2. **Full category filter, not just 4 shortcuts.** The old "Food type" row only offered
   Fruit/Vegetable/Dairy/Meat — Alcohol, Bakery, and the other ~15 real category values had no
   chip at all. `renderIngredientCategoryChips()` now derives the full list live from
   `_ingredients` (`Array.from(new Set(_ingredients.map(i=>i.category)))`) instead of a
   hardcoded array, so it can never drift out of sync with the real data (e.g. a new category
   typed into the Ingredient Audit's free-text category field just shows up automatically).
   Renamed the internal state (`ingredientActiveFoodType` → `ingredientActiveCategory`) and the
   sheet label ("Food type" → "Category") to match.
3. **New filter: Pricing (Verified / Estimated / Missing).** Directly addresses the standing
   data-quality caveat on this project — the original 535-row seed shipped with every price
   estimated, never verified online, and that's stayed true for anything added the same way
   since. `ingredientPricingStatus(ing)` classifies a row as "Verified" only if its `notes` field
   starts with "Price from " (the exact convention every real supplier-import batch writes,
   e.g. `db/46_supplier_ingredients.sql`), "Missing" if there's no price at all, "Estimated"
   otherwise. Lets Richard filter straight to "which of my prices are still placeholders" instead
   of finding out one row at a time.

**Verification**: same structural pass as every batch (braces/divs/buttons balanced, every
handler/id resolves — only the two known dynamic-id false positives remain), plus confirmed no
other code still referenced the old `ingredientActiveFoodType`/`renderIngredientFoodTypeChips`
names after the rename.

## ChefOS logo v2 — Richard's first pass looked too generic (2026-07-13, later still)

Richard: "ten qr kod je niečo hrozne... nepoužívaj takú farbu a sprav tomu viac umelecký font."
Replaced the plain system-font "C" (copper, bold sans) with a hand-built abstract mark: a bold
open ring drawn as one precise SVG arc (`M 46.8 42.3 A 18 18 0 1 1 46.8 21.7`, radius 18, stroke
7, plus a small center dot) instead of a font glyph — reads as a "C" through negative space, and
is immune to whatever fonts happen to be installed on Richard's phone since nothing in the mark
itself depends on font rendering. Colors moved off copper entirely to a deep sage on warm
cream, still pulled from the app's own existing palette (not a new color introduced from
nowhere). The "ChefOS" wordmark next to it on My Team also got a pass — was plain bold sans,
now Georgia italic in sage, a more editorial/elegant pairing with the mark. Same
`chefOSLogoMarkSvg(size)` function, so both the small brand header and the QR-code overlay pick
up the new design automatically with no other code changes.

## Pinned ingredient-count in the topbar (2026-07-13, later still)

Richard liked the filter sheet but wanted the match count visible without opening it — "aby bolo
vidieť vždy hneď koľko ingrediencií v danom filtri máme." Added `#ingredientStickyCount`, a small
line pinned right under the "Ingredients & Pricing" title in the sticky header. `updateIngredientFilterCount()`
now writes the same "N ingredients match this filter" text to both the sheet's copy and this
pinned one from one shared computation, and is called from inside `renderIngredientList()`
itself (added at the top, before its one early-return path) so both copies can never drift out
of sync with whatever's actually on screen, regardless of which code path triggered the re-render.

## Check List icon picker matched to Recipes' size (2026-07-13, later still)

Check List's "New Section" and "Edit Section" icon grids were still offering the original
30-icon `STATION_ICON_CHOICES` set, while Recipes had already been expanded to the 72-icon
`RECIPE_ICON_CHOICES` superset in an earlier batch. Richard: wants the same count in both.
Swapped all 4 remaining Check List call sites (`renderEditStationIconGrid()`,
`renderNewStationIconGrid()`, and `_newStationIcon`'s two default-value assignments) from
`STATION_ICON_CHOICES` to `RECIPE_ICON_CHOICES` — no new array, just pointing Check List at the
same superset Recipes already uses. `STATION_ICON_CHOICES` itself is untouched (still the base
30 that `RECIPE_ICON_CHOICES` spreads from).

## Language Audit — find and translate non-English Check List names (2026-07-13, later still)

Richard: go through every Check List name and fix anything not in English. I have no live
database access from this environment, so this ships as a new in-app tool he runs himself —
same shape as Ingredient Audit, which he's already used and liked.

**New: 🌐 Language Audit**, reached from Check List's ☰ Sections sheet. `runLanguageAudit()`
collects every distinct dish name (`prep_dishes`) and item name (`prep_items`), batches them
(100 per call) to Claude via a new `callClaudeTranslateNames()` — same direct-browser-fetch
pattern as every other AI feature in the app — asking it to flag only the names NOT already in
English and give each a natural English translation. Results render as per-item cards (name,
detected language, editable translation, usage count) with two actions: ✅ Translate (renames
every dish/item currently sharing that exact name — same "same real-world thing, same name
everywhere" convention as the existing kitchen-wide sync) or ✕ Skip. Nothing is renamed without
explicit per-item approval, same philosophy as Ingredient Audit's Add/Link/Ignore. A safety
filter discards any name Claude returns that doesn't exactly match something actually in the
scanned list, in case of paraphrasing.

**Still needed from Richard:** open Check List → ☰ → 🌐 Language Audit to actually run the scan
against his real data — I can't run it for him from here.

## Found and fixed two missing RLS policies (2026-07-13, later still)

Richard asked "aký SQL ti chýba?" — worth taking seriously, so audited every table this
session's features actually write to against the real RLS policies in `db/`. Found two real
gaps, both the silent-failure kind (Postgres RLS defaults to deny with no error surfaced unless
the client code specifically checks `error`), so neither would have been obvious until someone
actually hit the button in production:

1. **`kitchens` never had an UPDATE policy** — only ever inserted at kitchen creation and read
   for its name. The currency switcher (`47_kitchen_currency.sql`) is the first feature that
   ever needs to update a `kitchens` row itself (`display_currency`) — without a policy, that
   update would silently no-op for every admin who taps it.
2. **`station_icons` had select/insert/update policies but no DELETE policy.** The section
   rename feature (`saveEditStation()`) deletes the old station's icon row before upserting the
   new one under the renamed name — without this, the delete silently fails, leaving a stale
   orphaned icon row behind under the old station name.

**New: `db/48_kitchens_and_station_icons_policy_fix.sql`** — adds both missing policies
(kitchens UPDATE scoped to admins of that specific kitchen; station_icons DELETE matching the
existing kitchen-wide pattern used by its other three policies). Cross-checked every other table
touched by this session's features (`recipe_category_icons`, `prep_dishes`, `prep_items`,
`ingredients`) — all already have full select/insert/update/delete coverage, no other gaps found.

## Pilot kitchen changes from Hotel Schweizerhof to Burrito Bandito & Lido (2026-07-13, later still)

The backlog v2 expert review (see `app/backlog.html`) surfaced a real founder-level risk: ChefOS
was built during Richard's employment at Hotel Schweizerhof Bern AG, and its Check List prep
sheets were built from that hotel's real menu documents — Swiss law (OR Art. 332) can give an
employer rights over work-related output, and there's reportedly an active labor dispute with
the hotel concurrently, which raises the stakes considerably. Richard resolved this directly
rather than treating it as an open risk to manage around:

- **Hotel Schweizerhof data is being retired from ChefOS entirely** — not worth keeping given
  the IP exposure, and Richard is leaving that job anyway.
- **New pilot kitchen: Burrito Bandito & Lido** — one company, two separate venues. Confirmed
  and reflected in `app/presentation.html` (hero lede, Market KPI, staff-count KPI, pilot-kitchen
  KPI) and `docs/VISUAL_GUIDE.html`'s Schedule section description.
- **RC Studio (Richard's other venture) is shelved** — directly addresses the "capacity" risk
  the same review flagged (full-time new job + ChefOS + a third venture wasn't sustainable at
  the build pace this project has been running at).
- **First draft of a written pilot agreement** — `docs/PILOT_AGREEMENT.md`, covering what the
  app is (beta), what gets logged, that data belongs to the kitchen, a HACCP-output liability
  disclaimer for the test period, and the ability to stop anytime. Plain-language template, not
  lawyer-reviewed — flagged as such in the document itself.

**Not yet done — needs Richard's confirmation on scope before any SQL is written:** the actual
live-database purge of Schweizerhof-derived content (real staff/schedule data in
`db/19_schedule_v2_seed.sql`'s target tables, Check List prep-sheet content built from the
hotel's menus, and the one hotel-named recipe "Schweizerhof Brioche") — asked Richard directly
rather than guess, since recipes specifically were never called out as the IP risk in the
backlog's own assessment and guessing the wrong scope on a delete is not something to get wrong.
`backlog.html`'s two resolved founder-risk tickets and the still-open pilot-agreement ticket
updated to reflect all of this.

## Retired Schweizerhof branding from recipe/dish names (2026-07-13, later still)

Asked Richard to scope the live-data purge precisely rather than guess (recipes/schedule/prep-
sheets are three very different blast radii). His answer: only recipes/dishes literally named
after Schweizerhof need to go — schedule structure and the rest of the prep sheets aren't
actually their content ("nič iné som od nich nepoužil"). Searched every SQL file for
"Schweizerhof" inside an actual title/name (not a comment) and found exactly three: the recipe
"Schweizerhof Brioche", and two Check List dishes, "Schweizerhof Coq au Vin Blanc" and
"Schweizerhof Chocolate Mousse" (added via `29_translate_prep_sheets_en.sql`'s DE→EN pass, from
"Schweizerhof Schokoladenmousse").

**New: `db/49_retire_schweizerhof_naming.sql`** — renames all three (drops the "Schweizerhof "
prefix) rather than deleting them outright, since the underlying dishes are standard classics,
not the hotel's proprietary content — only the naming tied them to it. Flagged in the file
itself that a delete-instead-of-rename version is trivial if Richard would rather they were
gone entirely.

## Six critical/security items from the backlog v2 review, resolved (2026-07-13, later still)

Richard: "poďme na všetky kritické alebo bezpečnostné úlohy a blokery." Triaged every critical
item into what's actually codeable from here vs. what genuinely needs Richard's own accounts/
hardware/judgment, then did all six of the former:

1. **Git, finally.** The project had zero version control this whole time — `git init` +
   `.gitignore` + a first commit capturing the entire current state. Committing incrementally
   from here on. Pushing to a private GitHub remote still needs Richard's own account (no `gh`
   CLI or credentials available in this environment).
2. **Anthropic API key moved server-side.** It was previously sent from the browser straight to
   Anthropic on every AI call — readable in dev tools/network tab by anyone with device access.
   New `supabase/functions/claude-proxy` looks up each user's own key server-side (preserves the
   bring-your-own-key model, the key just never reaches the browser) and forwards the call; all
   9 `callClaudeXxx()` call sites in `app/index.html` now route through one shared
   `callClaudeAPI()` helper instead of hitting `api.anthropic.com` directly. Richard needs to run
   `supabase functions deploy claude-proxy` — no CLI access from here.
3. **Real-time sync — confirmed missing, now built.** MVP_DEFINITION.md promises "updates
   visible to everyone in real time"; there was no Realtime subscription anywhere in the
   codebase — every screen only ever loaded data once per visit. Added
   `subscribeToRealtimeUpdates()`, live on `prep_items`/`prep_dishes` for the current kitchen,
   merging changes straight into the existing local arrays. `db/50_enable_realtime.sql` still
   needs running (adds both tables to the `supabase_realtime` publication).
4. **Basic error tracking.** `db/51_error_logs.sql` + `window.onerror`/`unhandledrejection`
   handlers, capped at 20 logs/session so a tight error loop can't flood the table.
5. **Basic usage analytics.** `db/52_usage_events.sql` + a `logEvent()` call at login and at the
   top of every top-level module-entry function (Recipes, Check List, Ingredients, Order List,
   Fridge Temp, Chef's Assistant, Working Time, Print Labels, My Team, Admin).
6. **Expiring/revocable invite links + remove-a-member.** The invite link was literally the
   kitchen's own id (never expires, unrevokable without breaking the kitchen), and there was no
   way to remove someone from a team at all. `db/53_invite_expiry_and_remove_member.sql` adds a
   real `kitchen_invites` token (7-day expiry, revocable) plus RLS letting team members read
   each other's names (previously only your own profile row was visible to you at all) and
   letting an admin clear another member's `kitchen_id`. `showTeamInvite()` now mints/reuses a
   token instead of exposing the kitchen id, with a "Revoke & get a new link" button and a Team
   Members list with an admin-only Remove action. Old-format `?join=<kitchenId>` links already
   shared keep working as a legacy fallback.

**Also written (pure documentation, zero code risk): `docs/REGRESSION_CHECKLIST.md`** — a ~20-step
manual pass covering every major screen plus the two things most likely to have shipped with a
real bug today (Working Time's note field, and the brand-new cross-device realtime sync).
Richard still has to actually walk through it on a real device — that part can't be done from
here.

**Explicitly NOT attempted from here — genuinely needs Richard directly, not code:**
Resend domain verification / switch to Supabase's built-in mailer (blocks public-trial email
login), Supabase automatic-backups toggle + a real restore test, standing up a second
(staging) Supabase project, a cost cap/alert on the Anthropic account, checking/upgrading the
Supabase free-tier limits before 25 concurrent trial users, buying and testing the label
printer/fridge sensor hardware already researched, a short lawyer consult on the pilot
agreement and the new employment contract's IP clauses, device-matrix testing on real hardware,
and the handful of open product/business decisions (multi-tenant ingredient-table split, yield/
waste factor in food cost, billing platform choice, language strategy for the Bern trial).
These are logged as still-open in `app/backlog.html`, not silently dropped.

**Verification**: full structural pass on every edit (braces/divs/buttons balanced, every
handler/id resolves, no duplicate function definitions) — clean throughout. Committed each unit
of work as its own git commit rather than one giant commit at the end, now that there's a repo
to actually use.
