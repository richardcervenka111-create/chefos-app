#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sautero tile-lock runner (Richard, 22.7.2026 — "nadstavíme jednotlivé dlaždice a ich funkcie
a postupne ich zamkneme").

THE IDEA: once a tile is perfected and Richard declares it done, it gets LOCKED — its core
behaviours are written down as live browser tests here, the tile's key goes into
scripts/locked_tiles.json, and from then on the behaviours are re-verified on the LIVE app
after every deploy (tile-locks.yml runs on workflow_run after Deploy) and 2x/day. A regression
in a locked tile goes red the same day instead of waiting for a human to notice.

HOW THIS DIFFERS from the other layers:
  * e2e_smoke_test.py     — "does the screen open, does nothing crash" (shallow, all tiles)
  * calc_unit_test.js     — "is the arithmetic right" (pure functions, no browser)
  * tile_lock_test.py     — "does the BEHAVIOUR still work end-to-end" (deep, locked tiles only:
                            e.g. a check-in really stops the clock and stores the right time)

LOCKING PROTOCOL (never skip a step):
  1. Richard perfects the tile and says "zamkni <tile>".
  2. Write its behavioural checks as a `check_<tile>` function below, registered in CHECKS.
  3. LIVE-VERIFY the new checks against app.sautero.ch before committing (a broken lock test
     produces false red alerts, which erode trust in the whole board).
  4. Add the tile key to locked_tiles.json. From then on the lock is enforced automatically.

Each check function gets a logged-in Playwright page (the base QA account unless the check
logs in as another role itself) and raises AssertionError with a precise message on failure.
Tests must clean up any data they create.

Credentials come from the same GitHub secrets as the smoke test (SAUTERO_QA_*). With no tiles
locked the runner exits 0 with a note — the framework sits ready for the first lock.

USAGE:
  python3 scripts/tile_lock_test.py [--url https://app.sautero.ch] [--headed] [--only <tile>]
"""
import argparse
import json
import os
import sys

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Playwright not installed. Run: pip3 install playwright && python3 -m playwright install chromium")
    sys.exit(1)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(REPO, 'scripts', 'locked_tiles.json')

# Same tutorial mute as e2e_smoke_test.py — a fresh QA context triggers the first-run tutorial
# overlay, which sits ON TOP of the tile's buttons and made the first lock run time out on
# "waiting for element to be visible" (run #7, 22.7.). Pretend every tutorial was seen.
TUTORIAL_MUTE_SCRIPT = """(() => {
    const orig = Storage.prototype.getItem;
    Storage.prototype.getItem = function(k){
        if (k === 'chefos_tutorial_seen' || (typeof k === 'string' && k.indexOf('chefos_vtut_') === 0)) return '1';
        return orig.call(this, k);
    };
})()"""


def login(page, url, email, password):
    """Shared login helper — the same gate flow the smoke test uses."""
    page.goto(url, wait_until='networkidle', timeout=30000)
    # coming-soon wall -> sign-in reveal
    wall_btn = page.locator("button[onclick*='showLoginFromComingSoon']")
    if wall_btn.count() > 0 and wall_btn.first.is_visible():
        wall_btn.first.click()
    page.wait_for_selector('#loginEmail', state='visible', timeout=15000)
    page.fill('#loginEmail', email)
    if not page.locator('#loginPassword').is_visible():
        page.click('#passwordLoginToggleLink')
        page.wait_for_selector('#loginPassword', state='visible', timeout=5000)
    page.fill('#loginPassword', password)
    page.click("#loginPasswordBlock button:has-text('Sign in')")
    page.wait_for_selector('#homeView', state='visible', timeout=20000)
    dismiss_tutorials(page, 'after login')


def dismiss_tutorials(page, where):
    """Safety net, NOT a fix: the mute init-script should stop every tutorial. If one still
    opens, close it via the app's own closeTutorial() and PRINT that it happened — a printed
    dismissal means the mute failed again and needs investigating (Standard §7)."""
    closed = page.evaluate(
        "() => { const o = document.getElementById('tutorialOverlay');"
        " if(o && o.classList.contains('open') && typeof closeTutorial === 'function'){"
        " closeTutorial(); return true; } return false; }")
    if closed:
        print(f'    (!) tutorial overlay had to be force-closed {where} — the mute script did not stop it')


# ---------------------------------------------------------------------------
# Behavioural check suites — one function per LOCKED tile. Written and live-verified at lock
# time, never speculatively. Template:
#
# def check_working_time(page, ctx):
#     """Locked <date>: check-in starts the clock, check-out stops it and stores the right
#     duration; a logged break is deducted."""
#     ...open the tile, act, assert on real outcomes, clean up...
#
def check_working_time(page, ctx):
    """Locked 22.7.2026 (Richard: "working time funguje správne"). Behaviours under lock:
    check-in creates a running entry, the status card shows the live clock, check-out (with its
    confirm dialog) stores a checkout time within a sane distance of the check-in, and the entry
    is a real DB row. The test creates ONE real entry on the QA account and deletes it at the
    end with a row-count-verified delete (the 20.7 silent-no-op rule).

    SELECTOR RULE (root cause of runs #7-#9): target buttons by their exact onclick attribute —
    text selectors are ambiguous here ("Check In" also matches the hidden forgot-overlay's
    "Check in at this time"). And wait on READINESS SIGNALS (the button/clock appearing, the
    active entry clearing), never on fixed sleeps."""
    page.on('dialog', lambda d: d.accept())

    CHECKIN_BTN = 'button[onclick="checkInWorkingTime()"]'
    CHECKOUT_BTN = 'button[onclick="checkOutWorkingTime()"]'

    def open_tile():
        page.locator('.home-tile', has_text='Working Time').first.click(timeout=8000)
        # readiness = the tile's data loaded and the status card rendered ONE of the two states
        page.wait_for_selector(f'{CHECKIN_BTN}, {CHECKOUT_BTN}', state='attached', timeout=20000)
        dismiss_tutorials(page, 'after opening Working Time')

    open_tile()

    # Self-heal AFTER the tile loads (run #394 lesson: _activeTimeEntry is only populated by the
    # tile's own data load — checking it at Home always saw null, so a leftover open entry from
    # a crashed run kept the account checked-in and there was no Check In button to find).
    leftover = page.evaluate("() => (typeof _activeTimeEntry !== 'undefined' && _activeTimeEntry) ? _activeTimeEntry.id : null")
    if leftover:
        print(f'    (self-heal: deleting leftover open entry {leftover} from a previous crashed run)')
        deleted = page.evaluate("""async (id) => {
            const { data, error } = await sb.from('time_entries').delete().eq('id', id).select();
            return { n: (data || []).length, err: error ? error.message : null }; }""", leftover)
        assert deleted['err'] is None and deleted['n'] == 1, f'leftover cleanup failed: {deleted}'
        page.reload(wait_until='networkidle')
        page.wait_for_selector('#homeView', state='visible', timeout=20000)
        dismiss_tutorials(page, 'after self-heal reload')
        open_tile()

    page.wait_for_selector(CHECKIN_BTN, state='visible', timeout=20000)

    # 1) check in
    page.click(CHECKIN_BTN)
    page.wait_for_selector('#wtElapsed', state='visible', timeout=15000)
    entry_id = page.evaluate("() => (typeof _activeTimeEntry !== 'undefined' && _activeTimeEntry) ? _activeTimeEntry.id : null")
    assert entry_id, 'check-in did not create an active entry (_activeTimeEntry is null)'

    # 2) check out (auto-accepts the "Check out now?" confirm); done = active entry cleared
    page.wait_for_selector(CHECKOUT_BTN, state='visible', timeout=10000)
    page.click(CHECKOUT_BTN)
    page.wait_for_function("() => typeof _activeTimeEntry === 'undefined' || !_activeTimeEntry", timeout=15000)
    row = page.evaluate("""async (id) => {
        const { data } = await sb.from('time_entries').select('check_in, check_out').eq('id', id).single();
        return data; }""", entry_id)
    assert row and row.get('check_out'), f'check-out did not store a checkout time (row: {row})'
    from datetime import datetime
    ci = datetime.fromisoformat(row['check_in'].replace('Z', '+00:00'))
    co = datetime.fromisoformat(row['check_out'].replace('Z', '+00:00'))
    dur = (co - ci).total_seconds()
    assert 0 <= dur < 180, f'stored duration {dur:.0f}s is not the ~5s the test actually worked'
    still = page.evaluate("() => (typeof _activeTimeEntry !== 'undefined' && _activeTimeEntry) ? _activeTimeEntry.id : null")
    assert not still, 'after check-out the app still thinks an entry is running'

    # 3) cleanup — row-count-verified delete (never a silent no-op)
    deleted = page.evaluate("""async (id) => {
        const { data, error } = await sb.from('time_entries').delete().eq('id', id).select();
        return { n: (data || []).length, err: error ? error.message : null }; }""", entry_id)
    assert deleted['err'] is None and deleted['n'] == 1, f'cleanup delete failed: {deleted}'


def check_recipes(page, ctx):
    """Locked 22.7.2026 (Richard: "recepty sú tak ako si ich predstavujem"). Behaviours under lock:
    the Recipes list LOADS and RENDERS (the classic regression is an empty/broken list); opening a
    recipe shows its title and lands at ITS TOP (the 22.7. <body>-scroller fix — window.scrollTo is
    a no-op here, so this guards it for real); and a created recipe PERSISTS → shows on its shelf →
    DELETES. Create/delete uses the app's own data layer (the same insert shape as saveFormBody +
    loadAppData) with a row-count-verified cleanup, in whatever mode the account is in. Native
    dialogs are auto-accepted so a stray alert can't hang the run (verified 22.7.: a bare alert
    freezes the page)."""
    page.on('dialog', lambda d: d.accept())

    page.locator('.home-tile', has_text='Recipes').first.click(timeout=8000)
    # readiness: opening the tile loads the recipe data (the tile lands on the shelf PICKER, not
    # the list itself — verified 22.7.). Wait for the data, then enter the list deterministically
    # via showList() rather than depending on which shelf screen the picker shows.
    page.wait_for_function("() => typeof allRecipes === 'function' && allRecipes().length > 0", timeout=20000)
    page.evaluate("() => showList()")
    page.wait_for_function(
        "() => document.getElementById('listView') && "
        "getComputedStyle(document.getElementById('listView')).display === 'block'", timeout=10000)
    dismiss_tutorials(page, 'after opening Recipes')

    # 1) the list actually renders rows. Check the SHARED-LIBRARY shelf ('chefos') — it's the one
    #    shelf guaranteed non-empty for every account (the default 'mine' shelf is legitimately
    #    empty on an account with no personal recipes / in company mode, so it can't be the signal).
    rendered = page.evaluate("""() => {
        recipeSourceFilter = 'chefos';
        if (typeof activeCategory !== 'undefined') activeCategory = 'All';
        renderList();
        const c = document.getElementById('listContainer');
        if (!c) return { n: 0, empty: true };
        return { n: c.children.length, empty: !!c.querySelector('.empty-state') }; }""")
    assert rendered['n'] > 0 and not rendered['empty'], f'the shared-library shelf rendered nothing usable: {rendered}'

    # 2) a recipe opens at its top, with its title
    opened = page.evaluate("""() => {
        document.body.scrollTop = 300; document.documentElement.scrollTop = 300; window.scrollTo(0, 300);
        showDetail(0);
        const title = ((document.querySelector('#detailContent .recipe-title') || {}).textContent || '').trim();
        const scroll = window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0;
        return { hasTitle: !!title, scroll }; }""")
    assert opened['hasTitle'], 'opening a recipe did not render its title'
    assert opened['scroll'] == 0, f'recipe opened at scroll {opened["scroll"]} instead of its top'

    # 3) create -> persists -> on-shelf -> delete (row-count verified), in the account's own mode
    result = page.evaluate("""async () => {
        const u = await sb.auth.getUser(); const uid = u.data.user.id;
        const t = 'QA-LOCK-TEST ' + Date.now();
        const personal = (typeof currentAccountType !== 'undefined') ? currentAccountType === 'personal' : true;
        const ins = await sb.from('recipes').insert({ title: t, category: 'QA', kitchen_id: currentKitchenId,
            created_by: uid, is_custom: true, is_personal: personal, list_id: null }).select('id').single();
        if (ins.error) return { step: 'insert', err: ins.error.message };
        await loadAppData();
        recipeSourceFilter = personal ? 'mine' : 'company';
        const onShelf = allRecipes().filter(recipeOnCurrentShelf).some(r => r.title === t);
        const del = await sb.from('recipes').delete().eq('id', ins.data.id).select('id');
        await loadAppData();
        return { onShelf, deleted: (del.data || []).length, delErr: del.error ? del.error.message : null }; }""")
    assert not result.get('err'), f"recipe create failed ({result.get('step')}): {result.get('err')}"
    assert result['onShelf'], 'a freshly created recipe did not appear on its shelf'
    assert result['deleted'] == 1, f"cleanup delete removed {result['deleted']} row(s), expected 1"
    assert not result['delErr'], f"cleanup delete error: {result['delErr']}"


CHECKS = {
    'working_time': check_working_time,
    'recipes': check_recipes,
}
# ---------------------------------------------------------------------------


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--url', default='https://app.sautero.ch')
    ap.add_argument('--headed', action='store_true')
    ap.add_argument('--only', help='run a single tile key (for verifying a new lock)')
    args = ap.parse_args()

    reg = json.load(open(REGISTRY, encoding='utf-8'))
    locked = reg.get('locked', [])
    # Development workflow (Engineering Standard §3): the ONE module being actively developed
    # sits in "in_development" — its suite still runs and reports, but a failure is a WAIVED
    # warning, not a deploy block (its behaviour is legitimately in flux). Every other locked
    # module stays fully enforced. The waiver list must be emptied when the work is done.
    in_dev = set(reg.get('in_development', []))
    stray = in_dev - set(locked)
    if stray:
        print(f'tile_lock: FATAL — in_development lists {sorted(stray)} which are not locked tiles.')
        return 1
    if args.only:
        locked = [t for t in locked if t == args.only] or [args.only]
    if not locked:
        print('tile_lock: 0 tiles locked — nothing to enforce yet. The framework is armed; '
              'lock the first tile ("zamkni <dlaždica>") to activate it.')
        return 0

    missing = [t for t in locked if t not in CHECKS]
    if missing:
        print(f'tile_lock: FATAL — locked_tiles.json lists {missing} but no check suite exists. '
              f'A lock without a test is a lie; add the suite or unlock.')
        return 1

    email = os.environ.get('SAUTERO_QA_EMAIL')
    password = os.environ.get('SAUTERO_QA_PASSWORD')
    if not email or not password:
        print('tile_lock: SAUTERO_QA_EMAIL / SAUTERO_QA_PASSWORD not set — cannot run behavioural '
              'locks without the QA account. (Secrets exist in CI; export them locally to run here.)')
        return 1

    failures, waived = [], []
    details = {}
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not args.headed)
        for tile in locked:
            context = browser.new_context()
            page = context.new_page()
            page.add_init_script(TUTORIAL_MUTE_SCRIPT)
            errors = []
            bad_responses = []
            page.on('pageerror', lambda exc: errors.append(f'[pageerror] {exc}'))
            page.on('response', lambda r: bad_responses.append(f'{r.status} {r.url[:120]}') if r.status >= 500 else None)
            try:
                login(page, args.url.rstrip('/') + '/', email, password)
                CHECKS[tile](page, {'url': args.url, 'browser': browser})
                if errors:
                    raise AssertionError('uncaught JS during the check: ' + '; '.join(errors[:3]))
                if bad_responses:
                    raise AssertionError('5xx during the check: ' + '; '.join(sorted(set(bad_responses))[:3]))
                print(f'  [LOCK OK] {tile}')
            except Exception as e:
                details[tile] = str(e)[:300]
                # Failure diagnostics: a full-page screenshot + the list of visible top-level
                # views — CI uploads the PNGs as artifacts, so a red lock is debuggable from
                # facts, never from guesses (Engineering Standard §7).
                try:
                    page.screenshot(path=f'lock_fail_{tile}.png', full_page=True)
                    print(f'    (screenshot saved: lock_fail_{tile}.png)')
                except Exception:
                    pass
                try:
                    views = page.evaluate(
                        "() => [...document.querySelectorAll('body > div[id]')]"
                        ".filter(e=>getComputedStyle(e).display!=='none').map(e=>e.id).slice(0,15)")
                    print(f'    visible top-level views at failure: {views}')
                except Exception:
                    pass
                if tile in in_dev:
                    waived.append(tile)
                    print(f'  [LOCK DEV-WAIVED] {tile}: {details[tile]}')
                else:
                    failures.append(tile)
                    print(f'  [LOCK BROKEN] {tile}: {details[tile]}')
            finally:
                context.close()
        browser.close()

    # Root-cause report (Engineering Standard §1): the failing MODULE and its exact assertion
    # are the first thing anyone sees — in the console and in the GitHub job summary.
    summary_path = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary_path:
        with open(summary_path, 'a', encoding='utf-8') as f:
            f.write('## Tile locks\n')
            for t in locked:
                mark = '✅' if t not in details else ('⚠️ dev-waived' if t in waived else '❌ BROKEN')
                f.write(f'- **{t}** — {mark}' + (f': `{details[t]}`' if t in details else '') + '\n')
    if waived:
        print(f'\ntile_lock: {len(waived)} tile(s) waived as in-development: {", ".join(waived)} '
              f'(empty "in_development" in locked_tiles.json when the work is done).')
    if failures:
        print(f'\ntile_lock: {len(failures)}/{len(locked)} LOCKED tile(s) BROKEN: {", ".join(failures)}')
        for t in failures:
            print(f'  ROOT CAUSE [{t}]: {details[t]}')
        return 1
    print(f'\ntile_lock: all {len(locked)} locked tile(s) hold.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
