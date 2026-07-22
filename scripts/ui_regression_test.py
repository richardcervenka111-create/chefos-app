#!/usr/bin/env python3
"""UI/UX regression suite — real-browser guards for UX bugs that source-level checks can't see.

Complements scripts/ui_invariants.py (static) with behavioural tests that log in and exercise the
real app, the same way tile_lock_test.py guards locked tiles. This is for runtime UX that only a
browser reveals — e.g. "a recipe must open scrolled to its top", which depends on WHICH element is
the live scroll container (it's <body>, not window — window.scrollTo is a no-op here, 22.7.).

Uses the SAME login + tutorial-mute helpers as the lock suite (imported, not duplicated) and the
SAME secrets (SAUTERO_QA_*). Runs in the deploy gate against the candidate build, so a UX
regression stops the deploy before production sees it.

Run: python3 scripts/ui_regression_test.py [--url http://127.0.0.1:8080] [--headed]

Testing rule (Engineering Standard §7): if a check goes red, fix the ROOT CAUSE in the app or the
test — never weaken the assertion (no loosened tolerances, no removed checks) to make it pass.
"""
import argparse
import os
import sys

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Playwright not installed. Run: pip3 install playwright && python3 -m playwright install chromium")
    sys.exit(1)

# Reuse the exact login/mute flow the lock suite uses — one source of truth for auth.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tile_lock_test import login, TUTORIAL_MUTE_SCRIPT  # noqa: E402


def open_recipes(page):
    """Open the Recipes list and wait until recipes are actually loaded (readiness signal, not a
    fixed sleep). Returns nothing; raises on timeout."""
    page.evaluate("() => { if (typeof showRecipesHome === 'function') showRecipesHome(); }")
    # showRecipesHome opens the shelf picker on some states; fall back to showList directly.
    page.evaluate("() => { if (typeof showList === 'function') showList(); }")
    page.wait_for_function(
        "() => typeof allRecipes === 'function' && allRecipes().length > 1", timeout=20000)
    page.wait_for_function(
        "() => document.getElementById('listView') && "
        "getComputedStyle(document.getElementById('listView')).display === 'block'", timeout=10000)


def check_recipe_opens_at_top(page, ctx):
    """A recipe detail must ALWAYS open scrolled to its top, whatever the previous scroll position
    — both the list->detail path and the detail->detail (cross-reference) jump. Regression target:
    showDetail reset scroll with window.scrollTo(0,0), a no-op against the real <body> scroller, so
    recipes opened mid-page (22.7.)."""
    open_recipes(page)

    # Find two recipe indices whose detail is TALLER than the viewport, so the body can actually
    # be scrolled (a short recipe can't reproduce the bug). Uses the app's own showDetail render.
    tall = page.evaluate("""() => {
        const win = window.innerHeight, out = [];
        const n = Math.min(allRecipes().length, 40);
        for (let i = 0; i < n && out.length < 2; i++) {
            showDetail(i);
            if (document.body.scrollHeight > win + 300) out.push(i);
        }
        return out;
    }""")
    assert len(tall) >= 2, f'need 2 recipes taller than the viewport to test scrolling; found {tall}'
    a, b = tall[0], tall[1]

    def scroller_top():
        # read whichever root is the live scroller (matches the app's _appScrollY helper)
        return page.evaluate(
            "() => window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0")

    # --- Path 1: detail -> detail (cross-reference jump) ---
    page.evaluate("(i) => showDetail(i)", a)
    page.wait_for_function(
        "() => getComputedStyle(document.getElementById('detailView')).display === 'block'", timeout=8000)
    # scroll the detail down, then jump straight to another recipe
    page.evaluate("() => { document.body.scrollTop = 900; document.documentElement.scrollTop = 900; window.scrollTo(0,900); }")
    scrolled = scroller_top()
    assert scrolled > 200, f'could not scroll the recipe detail (top={scrolled}); test setup failed'
    page.evaluate("(j) => showDetail(j)", b)
    # the reset re-applies next animation frame, so wait for the signal, don't sleep
    try:
        page.wait_for_function("() => (window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0) === 0", timeout=5000)
    except Exception:
        raise AssertionError(f'recipe->recipe: detail opened at scroll {scroller_top()} instead of the top')

    # --- Path 2: list (scrolled) -> detail ---
    open_recipes(page)
    page.evaluate("() => { document.body.scrollTop = 700; document.documentElement.scrollTop = 700; window.scrollTo(0,700); }")
    page.evaluate("(i) => showDetail(i)", a)
    try:
        page.wait_for_function("() => (window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0) === 0", timeout=5000)
    except Exception:
        raise AssertionError(f'list->detail: recipe opened at scroll {scroller_top()} instead of the top')


CHECKS = {
    'recipe_opens_at_top': check_recipe_opens_at_top,
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--url', default='https://app.sautero.ch')
    ap.add_argument('--headed', action='store_true')
    ap.add_argument('--only', help='run a single check key')
    args = ap.parse_args()

    email = os.environ.get('SAUTERO_QA_EMAIL')
    password = os.environ.get('SAUTERO_QA_PASSWORD')
    if not email or not password:
        print('ui_regression: SAUTERO_QA_EMAIL / SAUTERO_QA_PASSWORD not set — cannot run browser '
              'UX checks without the QA account. (Secrets exist in CI; export them locally to run here.)')
        return 1

    checks = CHECKS
    if args.only:
        checks = {k: v for k, v in CHECKS.items() if k == args.only}
        if not checks:
            print(f'ui_regression: no check named {args.only}')
            return 1

    failures, details = [], {}
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not args.headed)
        for name, fn in checks.items():
            context = browser.new_context(viewport={'width': 390, 'height': 780})
            page = context.new_page()
            page.add_init_script(TUTORIAL_MUTE_SCRIPT)
            errors = []
            page.on('pageerror', lambda exc: errors.append(f'[pageerror] {exc}'))
            try:
                login(page, args.url.rstrip('/') + '/', email, password)
                fn(page, {'url': args.url, 'browser': browser})
                if errors:
                    raise AssertionError('uncaught JS during the check: ' + '; '.join(errors[:3]))
                print(f'  [UX OK] {name}')
            except Exception as e:
                failures.append(name)
                details[name] = str(e)[:300]
                print(f'  [UX FAIL] {name}: {details[name]}')
                try:
                    page.screenshot(path=f'ui_fail_{name}.png', full_page=False)
                except Exception:
                    pass
            finally:
                context.close()
        browser.close()

    # Job-summary line (same shape as tile_lock) for GitHub's step summary.
    summary = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary, 'a', encoding='utf-8') as fh:
            if failures:
                fh.write('### UI regression: FAIL\n')
                for n in failures:
                    fh.write(f'- **{n}** — {details[n]}\n')
            else:
                fh.write(f'### UI regression: all {len(checks)} UX check(s) green\n')

    if failures:
        print(f'\nui_regression: {len(failures)}/{len(checks)} UX check(s) FAILED: {", ".join(failures)}')
        return 1
    print(f'\nui_regression: clean — {len(checks)} UX check(s) green.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
