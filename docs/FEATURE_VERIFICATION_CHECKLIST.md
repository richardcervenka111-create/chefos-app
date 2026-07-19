# FEATURE_VERIFICATION_CHECKLIST.md

**Purpose:** the complete, feature-by-feature verification sweep Richard ordered on 19.7.2026
("keď sa zobudím, ideme na kompletnú kontrolu všetkých funkcií"). Walk it top to bottom
together, on a real phone + tablet. Every line gets ✅ / ❌ + a note. Anything ❌ becomes its
own fix with the Zero Feature Loss protocol (smallest step → pause → retest).

**Test matrix per feature — always check 4 perspectives where they apply:**
P1 Head Admin (icloud) · P2 company member (gmail/proton) · P3 personal mode · P4 company mode

## 0. Login & gates
- [ ] Email + code login · password login · Face ID unlock
- [ ] New-address flow: access request → approval gate → own kitchen creation
- [ ] Add Company invite → invitee lands approved and becomes that kitchen's admin (db/148)
- [ ] Add Team Member (code + QR + link + email) · Add Friend QR stays friend-only
- [ ] Coming-soon wall only for strangers with no invite context
- [ ] Confidentiality + privacy gates appear once, don't re-loop

## 1. Home
- [ ] All tiles present per role/mode (HACCP for everyone since 18.7.; Admin only for admins)
- [ ] Personal/company badge + quick toggle · tile reorder persists · language switcher

## 2. Check List (KDS) — heavy focus, most changed
- [ ] Project grid: personal mode = ONLY own private projects (db/159) — cross-check from
      second account that they're invisible (both modes)
- [ ] Company mode: team projects visible to all members; Add Project tile admin-only
- [ ] New project starts with just All + New Section (no default stations)
- [ ] Sections: create with icon · rename (Edit) · hide · delete = admin-only, member sees no
      delete anywhere (header button is gone for everyone)
- [ ] Dishes: collapsed by default, tap name opens ingredients; 👁️ visibility picker;
      long-press name → Rename/Hide/(Delete admin-only)
- [ ] Items: status buttons + per-item custom labels (long-press TO DO/CHECK/FINISH);
      priority sort inside section AND under All; on-hand; notes; ⏱ time log; ▶ timer;
      🔒 admin time locks per stage; ⋮ Edit name / Info / Delete; duplicate badge + name sync
- [ ] Scan prep sheet/menu (photo/PDF/URL) into a dish — lands in the right project/station
- [ ] Search FAB · Language Audit (admin) · audit trail shows who changed what
- [ ] NO phantom dialogs after closing any sheet (iPad!) · screen returns to position after
      keyboard closes (the 18.7. ghost-click + scroll fixes)

## 3. Order List
- [ ] 🛒 from Check List item / recipe ingredient — works for a PLAIN MEMBER with an unknown
      ingredient (db/154 shared-ingredient RPC), admin sees the item named correctly
- [ ] Personal mode orders: private to me, NEVER in company list, and vice versa (db/156) —
      verify from both accounts in both modes
- [ ] Summary: grouped by section, quantities summed, admin per-person breakdown,
      Remove mine, select-mode bulk delete, print
- [ ] Station picker (+): my checkboxes only mine; teammate totals hint

## 4. Recipes
- [ ] Shelves: My / Sautero / Company / Public + projects (colored books); shelf-scoped
      sections; My Recipes private, Public read-only escaped
- [ ] Detail: scaling, cost + calories, print, Add to Check List (project→station),
      Add ingredients to my list; comments cross-kitchen; per-friend sharing; favorites, notes
- [ ] Photo/menu-URL scan; Generate with AI (Chef's Assistant)
- [ ] Recipe projects: team-visible in company mode — check personal-mode creation privacy
      (KNOWN GAP: recipe_lists/ingredient_lists mode split = next atomic step, not yet done)

## 5. Ingredients
- [ ] Shelves: My / Sautero / Company / Public + custom lists; 2,005-item Sautero book
- [ ] KNOWN GAP (next step): list created in personal mode is team-visible (db/146) —
      confirm current behaviour, then fix lands with is_personal split
- [ ] Filters sheet (search, cuisine, category, price, season, storage, hidden) + live count
- [ ] AI Details · Invoice Scan — visible on personal/company AND Sautero shelf for admins
      (restored 19.7.); price-verification filter; price history; supplier field
- [ ] Custom Ingredients (admin): upload/scan file → review → save; Ingredient Audit
      (member! — db/154 path), sharing (public/friends), bulk delete, nutrition

## 6. Events (NEW 18.7. — first full test)
- [ ] Tile on Home · New Event manual (all fields, price in kitchen currency) · edit · delete
- [ ] Scan an order/e-mail photo → AI prefills the form → save
- [ ] Today | Tomorrow banners, later days nearest-first · 🎭 Demo toggle (Head Admin only,
      display-only) — and demo rows are NOT saved anywhere
- [ ] Kitchen-scope: what should a personal-mode user see here? (DECIDE with Richard — events
      table has no is_personal yet; same class as projects/orders)

## 7. HACCP
- [ ] Visible for every account incl. personal (18.7.)
- [ ] Cleaning checklist: 5-task demo seeds once for a virgin kitchen; ✅/⚠️ logging; admin
      sees WHO checked; manage (add/remove) tasks; hygiene analogous
- [ ] Fridge Temp (fridges + logs) · goods receiving · core cooking · cooling ·
      fryer oil · pest control · label expiry groups
- [ ] Staff Training + Report tiles show "coming soon" placeholders (wave 3)

## 8. Working Time
- [ ] Check-in/out + forgot flows + GPS snapshot; month view; day detail (orders+labels);
      contract upload + AI note (private bucket!); schedule scan → roster; charts;
      🎭 demo mode (Head Admin); day notes; personal orders EXCLUDED from work stats (19.7.)

## 9. Connections
- [ ] Scan QR (team vs friend distinction + confirm) · Invite Friend · Share My Recipe
      (per-friend) · Chef Friends list + friend profile shared content · My Team (name ✏️
      rename for Head Admin — 18.7., invite link/QR/revoke, members list, Make Assistant/Remove)

## 10. Print Labels
- [ ] Label settings per user · print/queue from Check List item · printAll logs to
      print_label_log · Label Expiry reflects use-by dates

## 11. Chef's Assistant
- [ ] Chat, substitutions, technique, recipe generation → save to shelf; AI credit gating for
      personal accounts; testing-mode toggle honored

## 12. Settings
- [ ] Account type switch (+ real-team gate) · currency (admin) · language · profile ·
      Preview as Normal User (admin) · tile reorder · sign out (+ ADIOS emergency)

## 13. Admin (Head Admin + company admin where applicable)
- [ ] Access Requests approve/deny · Admin Directory (roles, perms, presets, AI credit) ·
      Team Members · Add Company (→ full §0 flow) · Feedback inbox · AI Testing Mode ·
      AI Usage per user · Kitchen Reports (+ drill-down, demo) · Email Contacts (+ detail) ·
      Internal Docs (Richard's email only)

## 14. Documents (x7n2k9 / Internal Docs)
- [ ] All 5 merged docs open; tabs switch; inner anchors scroll IN PLACE (no banner stacking
      — 19.7. fix); external links open full-window; SK/EN toggle everywhere incl. banner
- [ ] Feature map tap-details; Now/Diary/Roadmap data current after tonight's doc-sync

## 15. Cross-cutting sweeps
- [ ] The "hrozne veľa vecí ktoré tam nie sú" list — Richard names every missing thing he
      remembers; each gets: (a) hidden by role/mode design? (b) hidden by recent change?
      (c) actually broken? → fix or explain, one by one
- [ ] Personal/company sweep of remaining tables (events, fridges, HACCP logs, print queue…)
- [ ] iPad: repeat §2/§3 flows watching for any phantom taps/scroll jumps
