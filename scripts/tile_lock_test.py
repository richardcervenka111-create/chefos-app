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


# ---------------------------------------------------------------------------
# Behavioural check suites — one function per LOCKED tile. Written and live-verified at lock
# time, never speculatively. Template:
#
# def check_working_time(page, ctx):
#     """Locked <date>: check-in starts the clock, check-out stops it and stores the right
#     duration; a logged break is deducted."""
#     ...open the tile, act, assert on real outcomes, clean up...
#
CHECKS = {
    # (no tiles locked yet — the first lock adds its suite here)
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

    failures = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not args.headed)
        for tile in locked:
            context = browser.new_context()
            page = context.new_page()
            errors = []
            page.on('pageerror', lambda exc: errors.append(f'[pageerror] {exc}'))
            try:
                login(page, args.url.rstrip('/') + '/', email, password)
                CHECKS[tile](page, {'url': args.url, 'browser': browser})
                if errors:
                    raise AssertionError('uncaught JS during the check: ' + '; '.join(errors[:3]))
                print(f'  [LOCK OK] {tile}')
            except Exception as e:
                failures.append(tile)
                print(f'  [LOCK BROKEN] {tile}: {str(e)[:300]}')
            finally:
                context.close()
        browser.close()

    if failures:
        print(f'\ntile_lock: {len(failures)}/{len(locked)} LOCKED tile(s) broken: {", ".join(failures)}')
        return 1
    print(f'\ntile_lock: all {len(locked)} locked tile(s) hold.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
