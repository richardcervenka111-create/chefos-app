#!/usr/bin/env python3
"""UI/UX invariants — static guards for the classes of UI bug we've actually hit (Richard, 22.7.).

These are SOURCE-level checks: fast, need no browser and no secrets, so they run on every push
(health-checks + the deploy gate). Each guard pins a specific past bug so it can't come back:

  1. Status pill (#bgScanPill) — the trailing status emoji must sit INSIDE the rounded cap.
     Bug (22.7.): right padding (16px) was smaller than the semicircular right cap radius, so a
     tall colour emoji spilled out of the bubble. Guard: right padding >= effective right radius.

  2. "Save where?" sheet (#scanSaveDestOverlay) — a sub-sheet opened FROM the menu-scan review
     must stack ABOVE it. Bug (22.7.): equal z-index + earlier DOM position => it opened BEHIND
     the review, invisible until the list was closed. Guard: its z-index > the base .sheet-overlay.

  3. AI photo cost logging — every successful image return in generate-image must be preceded by
     logImageUsage(), or Admin -> AI Usage silently misses this feature's cost. Guard: each
     `return json(200, { imageBase64 ... }` has a logImageUsage() call just above it.

  4. Scroll-to-top uses the REAL scroller — the live scroll container is <body>, not window, so
     window.scrollTo is a no-op (verified live 22.7.). Bug: recipes opened mid-page. Guard:
     _appScrollTo() is defined and showDetail() uses it (never a bare window.scrollTo as its reset).

  5. Personal/company toggle present + centered in BOTH top bars (Home + floating-nav), each in a
     .mode-toggle-zone centering wrapper — a refactor can't quietly drop it or knock it off-centre.

  6. Admin's icloud-only private tiles (Internal Docs, Error Logs) — present in ADMIN_TILE_DEFS,
     their onclick handlers defined, AND still gated to Richard's exact icloud email. The behavioural
     admin lock can't cover these (no QA account may see them, by design — Richard, "strážiť
     zvonku"), so this guards both their deletion and any loosening of that private gate.

  7. AI dish photo is restricted to the 4 internal accounts only (Richard's 5 points, #2) — the
     exact-4 allowlist, recipe_photo_gen kept dark, every ✨ generate button flag-gated, and the
     📷 Add-photo fallback always present for everyone else.

  8. Recipe remove-photo stays wired — removeRecipePhoto() defined and referenced at >=2 sites
     (recipe detail + edit form), so the Remove option can't silently vanish from either.

  9. Add-Company invite still grants the company-admin ROLE (db/169) — the guard honours the
     app.grant_company_admin GUC and claim_company_admin sets it, so an invitee joins as company
     admin, not a plain member (the 22.7. bug).

Run: python3 scripts/ui_invariants.py    (exit 1 on any failure)
Adding a new UI guard here when we fix a UI bug is part of the Engineering Standard (never let a
fixed UI bug regress silently).
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, 'app', 'index.html')
GEN_IMAGE = os.path.join(ROOT, 'supabase', 'functions', 'generate-image', 'index.ts')
DB169 = os.path.join(ROOT, 'db', '169_fix_company_admin_claim_role.sql')

# A pill is a short bar; its rounded cap can't curve in by more than ~half its height. If the
# right padding clears this, a right-aligned glyph is always drawn in the flat zone.
PILL_MAX_CAP_PX = 18

failures = []
passes = []


def read(path):
    with open(path, encoding='utf-8') as fh:
        return fh.read()


def find_element_style(html, element_id):
    """Return the inline style="..." string of the element with the given id, or None."""
    # match id="x" ... style="..."  OR  style="..." ... id="x" on the same tag
    m = re.search(r'id="' + re.escape(element_id) + r'"[^>]*?\sstyle="([^"]*)"', html)
    if not m:
        m = re.search(r'style="([^"]*)"[^>]*?\sid="' + re.escape(element_id) + r'"', html)
    return m.group(1) if m else None


def css_prop(style, name):
    m = re.search(r'(?:^|;)\s*' + re.escape(name) + r'\s*:\s*([^;]+)', style)
    return m.group(1).strip() if m else None


def px_list(value):
    """['9px','24px',...] -> [9.0, 24.0, ...] (non-px tokens like 'calc(...)' -> None)."""
    out = []
    for tok in value.split():
        m = re.match(r'^(-?\d+(?:\.\d+)?)px$', tok.strip())
        out.append(float(m.group(1)) if m else None)
    return out


# ---------------------------------------------------------------- 1. status pill containment
def check_status_pill(html):
    style = find_element_style(html, 'bgScanPill')
    if not style:
        failures.append('pill: could not find #bgScanPill inline style.')
        return
    padding = css_prop(style, 'padding')
    radius = css_prop(style, 'border-radius')
    if not padding or not radius:
        failures.append('pill: #bgScanPill is missing padding or border-radius.')
        return
    # padding: T R B L (or T RL, or all) -> right value
    pad = px_list(padding)
    if len(pad) == 4:
        pad_right = pad[1]
    elif len(pad) == 2:
        pad_right = pad[1]
    elif len(pad) == 1:
        pad_right = pad[0]
    else:
        pad_right = pad[1] if len(pad) > 1 else None
    if pad_right is None:
        failures.append(f'pill: could not read a px right-padding from "{padding}".')
        return
    # border-radius: TL TR BR BL (999px = full cap). Right corners = TR, BR.
    rad = css_prop(style, 'border-radius').split()
    def rad_px(tok):
        m = re.match(r'^(\d+(?:\.\d+)?)px$', tok)
        return float(m.group(1)) if m else 0.0
    if len(rad) >= 3:
        tr, br = rad_px(rad[1]), rad_px(rad[2])
    else:
        tr = br = rad_px(rad[0]) if rad else 0.0
    cap = min(max(tr, br), PILL_MAX_CAP_PX)   # a huge radius is clamped to the physical half-height
    if pad_right + 0.01 < cap:
        failures.append(
            f'pill: #bgScanPill right padding {pad_right}px < effective right cap {cap}px — a '
            f'right-aligned status emoji will spill out of the rounded bubble (the 22.7. bug). '
            f'Increase right padding or reduce the right border-radius.')
    else:
        passes.append(f'pill: status emoji stays inside the cap (right padding {pad_right}px >= cap {cap}px).')


# ---------------------------------------------------------- 2. save-dest sheet stacks on top
def check_save_dest_zindex(html):
    # base .sheet-overlay z-index
    m = re.search(r'\.sheet-overlay\s*\{[^}]*?z-index:\s*(\d+)', html)
    if not m:
        failures.append('sheet: could not find base .sheet-overlay z-index.')
        return
    base_z = int(m.group(1))
    style = find_element_style(html, 'scanSaveDestOverlay')
    if not style:
        failures.append('sheet: could not find #scanSaveDestOverlay inline style.')
        return
    z = css_prop(style, 'z-index')
    if z is None or not z.strip().isdigit():
        failures.append('sheet: #scanSaveDestOverlay has no explicit numeric z-index — it will '
                        'open BEHIND the menu-scan review (equal z + later DOM). The 22.7. bug.')
        return
    if int(z) <= base_z:
        failures.append(f'sheet: #scanSaveDestOverlay z-index {z} <= base .sheet-overlay {base_z} — '
                        f'the "Save where?" sheet must stack ABOVE the review list.')
    else:
        passes.append(f'sheet: "Save where?" stacks above the review (z {z} > base {base_z}).')


# ------------------------------------------------------------- 3. AI photo cost logging present
def check_image_cost_logging(ts):
    lines = ts.splitlines()
    ok = True
    seen = 0
    for i, line in enumerate(lines):
        if 'return json(200' in line and 'imageBase64' in line:
            seen += 1
            # look at the up-to-3 preceding non-blank lines for the logging call
            window = '\n'.join(lines[max(0, i - 3):i])
            if 'logImageUsage(' not in window:
                ok = False
                failures.append(f'cost: generate-image line {i+1} returns an image without a '
                                f'preceding logImageUsage() — Admin AI Usage would miss its cost.')
    if seen == 0:
        failures.append('cost: no `return json(200, { imageBase64 ... }` found in generate-image — '
                        'did the success shape change? Update this guard.')
    elif ok:
        passes.append(f'cost: all {seen} image successes log their cost before returning.')


# --------------------------------------------------------- 4. scroll-to-top uses real scroller
def check_scroll_helper(html):
    if '_appScrollTo' not in html or 'function _appScrollTo' not in html:
        failures.append('scroll: _appScrollTo() helper is missing — full-page views must reset the '
                        'real body scroller, not window (window.scrollTo is a no-op here).')
        return
    m = re.search(r'function showDetail\(idx\)\{(.*?)\n\}\n', html, re.S)
    body = m.group(1) if m else ''
    if not m:
        # fall back to a generous slice
        idx = html.find('function showDetail(idx){')
        body = html[idx:idx + 4000] if idx >= 0 else ''
    if '_appScrollTo(0)' not in body:
        failures.append('scroll: showDetail() no longer resets via _appScrollTo(0) — a recipe will '
                        'open at the previous scroll position instead of its top (the 22.7. bug).')
    else:
        passes.append('scroll: showDetail() resets the real scroller via _appScrollTo(0).')


# ------------------------------------------- 5. personal/company toggle present + centered
def check_mode_toggle(html):
    # Richard, 22.7.: the personal/company toggle must live centered in the top bar on EVERY
    # screen. Guard both instances (Home badge + floating-nav) and that each sits in a centering
    # .mode-toggle-zone, so a refactor can't quietly drop it or knock it off-centre.
    ok = True
    for tid in ('homeAccountTypeBadge', 'navAccountTypeToggle'):
        if f'id="{tid}"' not in html:
            ok = False
            failures.append(f'toggle: #{tid} is missing — the personal/company toggle must show '
                            f'centered in the top bar on every screen.')
    zones = html.count('class="mode-toggle-zone"')
    if zones < 2:
        ok = False
        failures.append(f'toggle: expected 2 .mode-toggle-zone wrappers (Home + floating-nav), '
                        f'found {zones} — the toggle centering wrapper was dropped.')
    if ok:
        passes.append('toggle: personal/company toggle present + centered in both top bars.')


# ------------------------- 6. Admin's icloud-only private tiles present AND still icloud-gated
def check_admin_private_tiles(html):
    # Richard, 22.7. ("strážiť zvonku"): Internal Docs + Error Logs are gated to Richard's exact
    # icloud email ALONE (not just is_admin), so no QA account can see them and the behavioural
    # admin lock deliberately can't. This static guard covers both regressions the behavioural test
    # can't: (a) the tile being deleted, and (b) its gate being quietly loosened to a broader
    # audience. For each: the ADMIN_TILE_DEFS entry exists, its onclick handler is defined, and its
    # adminOnly gate still checks the exact icloud email.
    tiles = {
        'internalDocs': ('openInternalDocs', 'function openInternalDocs('),
        'errorLogs':   ('openAdminErrorLogs', 'function openAdminErrorLogs('),
    }
    gate_email = 'richard.cervenka@icloud.com'
    for key, (handler, handler_def) in tiles.items():
        m = re.search(r"key:\s*'" + re.escape(key) + r"'.*?adminOnly:\s*\(\)\s*=>\s*([^}]+)",
                      html, re.S)
        if not m:
            failures.append(f"admin-tiles: ADMIN_TILE_DEFS entry key:'{key}' is missing — the "
                            f"Internal Docs / Error Logs tile was removed from the Admin hub.")
            continue
        gate = m.group(1)
        if gate_email not in gate.lower():
            failures.append(f"admin-tiles: key:'{key}' is no longer gated to the exact icloud email "
                            f"({gate_email}) — its private gate was loosened. Restore the exact-email "
                            f"check or decide this deliberately.")
        elif handler_def not in html:
            failures.append(f"admin-tiles: key:'{key}' points at {handler}() but that function is "
                            f"not defined — the tile would error on tap.")
        else:
            passes.append(f"admin-tiles: '{key}' present, {handler}() defined, still icloud-only.")


# ------------------------------- 7. AI dish photo is restricted to the 4 internal accounts only
def check_ai_photo_gate(html):
    # Richard, 22.7. (his 5 points, #2): AI photo generation must stay available ONLY to the four
    # internal accounts; EVERY other account gets the plain "Add photo" instead. Guard the whole
    # gate so it can't silently open to everyone or drop the always-on Add-photo fallback:
    #   (a) the 4 exact internal emails are the allowlist,
    #   (b) recipe_photo_gen is DARK (enabled:false) — so only the allowlist (or f.allow) passes,
    #   (c) every render-site ✨ generateRecipePhoto() button sits behind featureEnabled(...),
    #   (d) the 📷 addRecipePhoto() button exists and is NOT flag-gated (always available).
    expected = ['richard.cervenka@icloud.com', 'richard.cervenka111@gmail.com',
                'chefos@protonmail.com', 'sautero_android@proton.me']
    m = re.search(r'FEATURE_FLAG_INTERNAL_ACCOUNTS\s*=\s*\[(.*?)\]', html, re.S)
    if not m:
        failures.append('ai-photo: FEATURE_FLAG_INTERNAL_ACCOUNTS list not found.')
    else:
        block = m.group(1).lower()
        missing = [e for e in expected if e not in block]
        if missing:
            failures.append(f'ai-photo: internal-accounts allowlist is missing {missing} — AI photo '
                            f'access must be exactly those 4 accounts.')
        else:
            passes.append('ai-photo: AI generation allowlisted to exactly the 4 internal accounts.')
    if not re.search(r'recipe_photo_gen\s*:\s*\{\s*enabled\s*:\s*false', html):
        failures.append("ai-photo: recipe_photo_gen is no longer { enabled: false } — the AI photo "
                        "feature would open to EVERYONE, not just the 4 internal accounts.")
    else:
        passes.append('ai-photo: recipe_photo_gen flag stays dark (internal accounts only).')
    # every render-site generate button is behind the flag — the featureEnabled('recipe_photo_gen')
    # check may be on the same line (`if(...) html += <button ...>`) or open a block on one of the
    # preceding lines (`if(...){` then the button). Accept either.
    lines = html.splitlines()
    ungated = []
    for i, ln in enumerate(lines):
        if 'onclick="generateRecipePhoto()"' not in ln:
            continue
        window = '\n'.join(lines[max(0, i - 2):i + 1])
        if "featureEnabled('recipe_photo_gen')" not in window:
            ungated.append(i + 1)
    if ungated:
        failures.append(f'ai-photo: generateRecipePhoto() button(s) at line(s) {ungated} are NOT '
                        f'behind featureEnabled(\'recipe_photo_gen\') — AI would show for everyone.')
    else:
        passes.append('ai-photo: every ✨ AI-generate button is flag-gated.')
    if 'onclick="addRecipePhoto()"' not in html:
        failures.append('ai-photo: the always-on 📷 Add photo button (addRecipePhoto) is missing — '
                        'non-internal accounts would have no way to add a photo.')
    else:
        passes.append('ai-photo: 📷 Add photo is always available (non-internal accounts covered).')


# ------------------------------------------------- 8. recipe remove-photo option stays wired up
def check_remove_photo(html):
    # Richard, 22.7.: a recipe photo must be removable — from the detail AND from the edit form.
    # Guard: removeRecipePhoto() is defined and wired at >=2 sites (detail actions + edit form).
    if 'function removeRecipePhoto(' not in html:
        failures.append('remove-photo: removeRecipePhoto() is not defined — the Remove-photo option '
                        'would error on tap.')
        return
    sites = html.count('removeRecipePhoto()') - 1  # minus the definition itself
    if sites < 2:
        failures.append(f'remove-photo: removeRecipePhoto() is wired at only {sites} button site(s) '
                        f'(expected >=2: recipe detail + edit form) — the Remove option was dropped '
                        f'from one of them.')
    else:
        passes.append(f'remove-photo: Remove photo wired at {sites} sites (detail + edit form).')


# ---------------------------- 9. Add-Company invite grants the company-admin ROLE (db/169 intact)
def check_company_admin_claim(sql):
    # Richard, 22.7.: someone added via Add Company joined as a plain MEMBER instead of company
    # admin, because the db/85 guard blocked claim_company_admin's admin_perms write. db/169 fixed
    # it with a transaction-local GUC. Guard both halves so the fix can't silently unravel:
    #   - the guard honours the trusted GUC (current_setting('app.grant_company_admin')),
    #   - claim_company_admin flips that GUC on before writing admin_perms.
    if "current_setting('app.grant_company_admin'" not in sql:
        failures.append("company-admin: db/169 guard no longer checks the app.grant_company_admin "
                        "GUC — Add-Company invitees would drop back to plain members.")
    elif "set_config('app.grant_company_admin', 'on', true)" not in sql:
        failures.append("company-admin: claim_company_admin no longer sets app.grant_company_admin "
                        "before the admin_perms write — the guard will block the role grant.")
    else:
        passes.append('company-admin: Add-Company invite still grants the company-admin role (db/169).')


# ------------------- 10. no focusable input under 16px (iOS Safari auto-zoom → app cut off right)
def check_input_font_size(html):
    # Richard, 22.7. ("strany nesedia"): iOS Safari auto-zooms into any focused input/textarea whose
    # font-size is < 16px and often never zooms back out, leaving the WHOLE app zoomed so the layout
    # is wider than the visible area and everything is cut off on the right. The chat input at 15px
    # was the trigger. Guard the specific control that caused it + the app-wide baseline rule.
    m = re.search(r'\.chef-chat-input\{[^}]*?font-size:\s*(\d+(?:\.\d+)?)px', html, re.S)
    if not m:
        failures.append('ios-zoom: could not find .chef-chat-input font-size to verify.')
    elif float(m.group(1)) < 16:
        failures.append(f'ios-zoom: .chef-chat-input font-size is {m.group(1)}px (<16px) — iOS Safari '
                        f'will auto-zoom on focus and leave the whole app cut off on the right.')
    else:
        passes.append(f'ios-zoom: chat input is {m.group(1)}px (>=16px), no iOS auto-zoom.')
    if not re.search(r'input,\s*textarea,\s*select\{\s*font-size:16px', html):
        failures.append('ios-zoom: the app-wide >=16px input baseline (input,textarea,select) is gone '
                        '— a sub-16px input can re-trigger the iOS zoom-and-cut-off bug.')
    else:
        passes.append('ios-zoom: app-wide >=16px input baseline present.')


# ---------------- 11. .home-tile must not collapse the grid on iOS Safari (aspect-ratio + min-width)
def check_home_tile_min_width(html):
    # Richard, 22.7. — the recipe shelf grid dropped from 3 columns to 2 big ones on his iPhone (only
    # in the classic theme), pushing the 3rd column (Company Recipes) off-screen. Cause: .home-tile
    # has aspect-ratio:1 in a grid, and a grid item's default min-width:auto lets iOS Safari transfer
    # the aspect ratio through the minimum, so the square tile refuses to shrink to the 1fr track.
    # min-width:0 (or overflow:hidden, which theme-new happened to have) forces the automatic minimum
    # to 0. Guard the base .home-tile carries the escape hatch so the grid can't collapse again.
    m = re.search(r'(?<!theme-new )\.home-tile\{(.*?)\}', html, re.S)
    if not m:
        failures.append('home-tile: could not find the base .home-tile rule to verify.')
        return
    body = m.group(1)
    if 'aspect-ratio' not in body:
        passes.append('home-tile: no aspect-ratio on the base tile — grid can\'t collapse this way.')
        return
    if re.search(r'min-width:\s*0', body) or re.search(r'overflow:\s*hidden', body):
        passes.append('home-tile: aspect-ratio tile has min-width:0/overflow:hidden — iOS grid stays 3-col.')
    else:
        failures.append('home-tile: .home-tile has aspect-ratio but no min-width:0 (or overflow:hidden) '
                        '— iOS Safari will collapse the shelf/home grid from 3 columns to 2 and push the '
                        'last column off-screen.')


def check_save_dest_mode_split(html):
    # Richard, 22.7. (CRITICAL privacy) — the "Save where?" sheet (openScanSaveDestSheet) listed
    # PERSONAL recipe projects while the account was in COMPANY mode, because _recipeLists is only
    # refreshed by showRecipesHome() and the sheet mapped it raw. Personal data must never surface in
    # a company view. Guard two things in openScanSaveDestSheet:
    #   1. the project options are built through an is_personal / mode filter, not a raw _recipeLists.map
    #   2. the function reloads recipe_lists with recipeListsModeFilter so a stale wrong-mode list can't leak
    m = re.search(r'function openScanSaveDestSheet\(mode\)\{(.*?)\n\}', html, re.S)
    if not m:
        # async form
        m = re.search(r'async function openScanSaveDestSheet\(mode\)\{(.*?)\n\}', html, re.S)
    if not m:
        failures.append('save-dest: could not find openScanSaveDestSheet to verify the mode split.')
        return
    body = m.group(1)
    has_filter = re.search(r'\.filter\(\s*l\s*=>.*is_personal', body, re.S)
    has_reload = 'recipeListsModeFilter' in body
    raw_map = re.search(r'\(_recipeLists\s*\|\|\s*\[\]\)\s*\.map', body)
    if has_filter and has_reload and not raw_map:
        passes.append('save-dest: openScanSaveDestSheet reloads + is_personal-filters projects — no cross-mode leak.')
    else:
        why = []
        if not has_filter: why.append('no is_personal .filter on the project options')
        if not has_reload: why.append('no recipeListsModeFilter reload')
        if raw_map: why.append('still maps _recipeLists raw (unfiltered)')
        failures.append('save-dest: openScanSaveDestSheet may leak the other mode\'s recipe projects — '
                        + '; '.join(why) + '. In company mode this shows PERSONAL projects (privacy leak).')


def check_recipe_copy_is_personal(html):
    # Companion to the sheet guard: when a recipe copy is filed into a project, its is_personal must
    # follow the current mode, never a hardcoded true. `is_personal: dest === 'company' ? false : true`
    # filed every company-project copy as personal (Richard, 22.7.).
    if "? false : true,\n" in html and 'list_id: dest ===' in html:
        # crude but targeted: the exact buggy ternary paired with a list_id dest line
        bad = re.search(r"is_personal:\s*dest === 'company' \? false : true", html)
        if bad:
            failures.append('recipe-copy: a project-copy insert hardcodes is_personal true '
                            '(is_personal: dest===\'company\' ? false : true) — in company mode this files '
                            'the recipe as personal. Derive it from currentAccountType instead.')
            return
    passes.append('recipe-copy: project-copy inserts derive is_personal from the current mode.')


def check_saving_overlay(html):
    # Richard, 22.7. — saving an AI recipe gave no sign anything was happening; added a blocking
    # "Saving your recipe…" spinner. Guard the three properties that made it correct:
    #   1. the #savingOverlay element exists,
    #   2. both save paths (saveGeneratedRecipe + saveFormBody) actually show it,
    #   3. hideSavingOverlay uses setTimeout — NOT requestAnimationFrame, which throttles to a stop
    #      in a backgrounded tab and could leave the scrim stuck over the whole app forever.
    problems = []
    if 'id="savingOverlay"' not in html:
        problems.append('#savingOverlay element missing')
    if html.count('showSavingOverlay(') < 3:  # def + 2 call sites (both save paths)
        problems.append('showSavingOverlay not called from both save paths')
    m = re.search(r'function hideSavingOverlay\(\)\{(.*?)\n\}', html, re.S)
    if not m:
        problems.append('hideSavingOverlay() not found')
    else:
        body = m.group(1)
        if 'requestAnimationFrame(' in body:  # a CALL, not the word in the explanatory comment
            problems.append('hideSavingOverlay uses requestAnimationFrame — can stick open in a '
                            'backgrounded tab; use setTimeout')
        if 'setTimeout' not in body:
            problems.append('hideSavingOverlay never schedules the hide (no setTimeout)')
    if problems:
        failures.append('saving-overlay: ' + '; '.join(problems) + '.')
    else:
        passes.append('saving-overlay: present, shown from both save paths, hidden via setTimeout (never sticks).')


def check_ingredient_info_panel(html):
    # Richard, 23.7. (t13) — the shared ingredient "i" panel (ingredientInfoHtml, used by the LOCKED
    # Recipes tile + Check List + Ingredients) gained a free Wikipedia link, an on-demand AI
    # flavour/origin/season button, and a stored Flavour row. Guard all three so an edit to that
    # heavily-shared function can't silently drop them.
    m = re.search(r'function ingredientInfoHtml\(rowName\)\{(.*?)\n\}', html, re.S)
    problems = []
    if not m:
        problems.append('ingredientInfoHtml() not found')
    else:
        body = m.group(1)
        if 'wikipedia.org' not in body: problems.append('no Wikipedia link')
        if 'generateIngredientAiInfo(' not in body: problems.append('no AI flavour/origin/season button')
        if 'ing.flavour' not in body: problems.append('no stored Flavour row')
    if 'async function generateIngredientAiInfo(' not in html:
        problems.append('generateIngredientAiInfo() handler missing')
    if problems:
        failures.append('ingredient-info: ' + '; '.join(problems) + '.')
    else:
        passes.append('ingredient-info: "i" panel keeps Wikipedia link + AI button + stored Flavour row.')


def main():
    html = read(APP)
    check_status_pill(html)
    check_save_dest_zindex(html)
    check_save_dest_mode_split(html)
    check_recipe_copy_is_personal(html)
    check_saving_overlay(html)
    check_ingredient_info_panel(html)
    check_scroll_helper(html)
    check_mode_toggle(html)
    check_admin_private_tiles(html)
    check_ai_photo_gate(html)
    check_remove_photo(html)
    check_input_font_size(html)
    check_home_tile_min_width(html)
    if os.path.exists(DB169):
        check_company_admin_claim(read(DB169))
    else:
        failures.append('company-admin: db/169_fix_company_admin_claim_role.sql not found.')
    if os.path.exists(GEN_IMAGE):
        check_image_cost_logging(read(GEN_IMAGE))
    else:
        failures.append('cost: generate-image/index.ts not found.')

    for p in passes:
        print('  ok  ' + p)
    if failures:
        print()
        for f in failures:
            print('  FAIL ' + f)
        print(f'\nui_invariants: {len(failures)} UI guard(s) FAILED.')
        return 1
    print(f'\nui_invariants: clean — {len(passes)} UI guard(s) holding.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
