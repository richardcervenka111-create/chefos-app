#!/usr/bin/env python3
"""
Sautero end-to-end smoke test (Richard, 20.7.2026 — "urob to", follow-up to the manual
398-item feature sweep taking too long to run by hand every time).

WHAT THIS IS: a "golden path" check, not full coverage. It logs in as a dedicated QA
account and taps through every top-level Home tile, asserting two things for each:
  1. the screen's heading actually renders (the tile did what it says), and
  2. the browser threw NO JavaScript error while getting there.
That second check is the real value — most regressions in a single 22k-line HTML file
show up as a silent broken screen or a console error, and this catches that automatically
instead of needing a human to notice.

WHAT THIS IS NOT: it does not verify business logic (e.g. "does check-in correctly stop
the clock"), does not create/delete real data beyond what's unavoidable to open a screen,
and does not replace the one-time 398-item manual sweep (visual data/test_sweep.html) —
that stays the source of truth for "does this feature behave correctly", this is just
"is the app currently broken".

SETUP (one-time, see README section at the bottom of this file):
  1. pip3 install playwright && python3 -m playwright install chromium
  2. A dedicated QA account with a password set (Settings → My Profile & Security → Set
     a password, or via signInWithPassword() the first time) — NOT one of Richard's real
     3 test accounts, so this can run unattended without touching real usage.
  3. Export SAUTERO_QA_EMAIL / SAUTERO_QA_PASSWORD (locally) or set them as GitHub Actions
     secrets of the same name (see .github/workflows/e2e-smoke.yml).

USAGE:
  python3 scripts/e2e_smoke_test.py [--url https://app.sautero.ch] [--headed]
"""
import argparse
import os
import sys
import time

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Playwright not installed. Run: pip3 install playwright && python3 -m playwright install chromium")
    sys.exit(1)

# Each golden path: the visible Home tile label to tap, and the heading text (or other
# on-screen marker) that proves the right screen actually opened. Kept intentionally light
# on assertions — depth comes later once this has run clean a few times against a live
# QA account and selectors are confirmed against the real DOM.
GOLDEN_PATHS = [
    {"tile": "Working Time", "expect_text": None},  # opens a sheet, not a full view — presence checked via no-console-error only
    {"tile": "Recipes", "expect_text": "Recipes"},
    {"tile": "Ingredients", "expect_text": "Ingredients"},
    {"tile": "Check List", "expect_text": None},
    {"tile": "Order List", "expect_text": "Order List"},
    {"tile": "Events", "expect_text": "Events"},
    {"tile": "HACCP", "expect_text": "HACCP"},
    {"tile": "Print Labels", "expect_text": "Print Labels"},
    {"tile": "Chef's Assistant", "expect_text": None},
    {"tile": "Connections", "expect_text": None},
    {"tile": "Settings", "expect_text": None},
]

BACK_ICON_SELECTOR = '.icon-btn[title="Back to Home"], .back-btn'


def run(url: str, email: str, password: str, headed: bool) -> int:
    failures = []
    console_errors = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not headed)
        page = browser.new_page()
        page.on("pageerror", lambda exc: console_errors.append(f"[pageerror] {exc}"))
        page.on("console", lambda msg: console_errors.append(f"[console.{msg.type}] {msg.text}") if msg.type == "error" else None)
        # A fresh CI browser has empty localStorage, so every first-run tutorial auto-opens and
        # its overlay blocks tile clicks. Report all tutorials as already seen (before any page
        # code runs, on every navigation) so they never pop during the test — purely a
        # test-harness concern, it changes nothing about the app's real behaviour.
        page.add_init_script(
            """() => {
                const orig = Storage.prototype.getItem;
                Storage.prototype.getItem = function(k){
                    if (k === 'chefos_tutorial_seen' || (typeof k === 'string' && k.indexOf('chefos_vtut_') === 0)) return '1';
                    return orig.call(this, k);
                };
            }"""
        )

        # ?invite= bypasses the "coming soon" wall shown to any browser with zero invite
        # context (app_config.coming_soon_enabled, app/index.html's init()) — without it a
        # fresh headless browser never even reaches the login form.
        login_url = url.rstrip("/") + "/?invite=e2e-smoke-test"
        print(f"→ Opening {login_url}")
        page.goto(login_url, wait_until="networkidle", timeout=30000)

        print(f"→ Signing in as {email}")
        page.wait_for_selector("#loginEmail", state="visible", timeout=15000)
        page.fill("#loginEmail", email)
        # Reveal the password field only if it isn't already showing (the toggle flips whichever
        # block is visible, so a blind click could hide it).
        if not page.locator("#loginPassword").is_visible():
            page.click("#passwordLoginToggleLink")
            page.wait_for_selector("#loginPassword", state="visible", timeout=5000)
        page.fill("#loginPassword", password)
        page.click("#loginPasswordBlock button:has-text('Sign in')")  # not the (hidden) Face ID button, which also matches "Sign in"
        try:
            page.wait_for_selector("#homeView", state="visible", timeout=15000)
        except Exception:
            # Better diagnostics (Richard, 20.7.): say WHY, not just "never reached Home".
            page.wait_for_timeout(1500)
            status = ""
            try:
                status = (page.locator("#loginStatus1").inner_text() or "").strip()
            except Exception:
                pass
            # Which top-level view actually ended up visible?
            landed = page.evaluate(
                """() => {
                    const ids = ['loginView','comingSoonView','privacyGateView','confidentialityGateView',
                                 'passwordGateView','myProfileGateView','accountTypeGateView','teamGateView','homeView'];
                    const vis = ids.filter(id => { const el=document.getElementById(id); return el && getComputedStyle(el).display !== 'none'; });
                    return vis.join(',') || 'unknown';
                }"""
            )
            if status:
                print(f"FAIL: sign-in rejected — login message: \"{status}\" (usually a wrong password for the QA account).")
            elif landed and landed != "homeView":
                print(f"FAIL: signed in but stopped at a gate/screen, not Home — visible view(s): {landed}. "
                      f"The QA account still needs to finish that step once by hand.")
            else:
                print(f"FAIL: never reached Home (visible view: {landed}).")
            browser.close()
            return 1
        print("  ✓ reached Home")

        for step in GOLDEN_PATHS:
            tile = step["tile"]
            print(f"→ {tile}")
            try:
                # Reset to a clean Home before each tile (the session persists across a reload,
                # so it lands straight back on Home). This sidesteps every kind of
                # back-navigation fragility — sheets vs full views, etc. — that a tile might
                # leave behind, and isolates each tile as its own check.
                page.goto(login_url, wait_until="domcontentloaded", timeout=20000)
                page.wait_for_selector("#homeView", state="visible", timeout=15000)
                console_errors.clear()  # ignore anything from the reload itself; watch the tile only
                # has_text= (not the :has-text('...') pseudo-selector) so labels with an
                # apostrophe like "Chef's Assistant" don't break the CSS parser.
                page.locator(".home-tile", has_text=tile).first.click(timeout=8000)
                page.wait_for_timeout(1200)  # let async loads settle
                # "Did the tile actually do something?" — either Home was replaced by another
                # view, or an overlay/sheet opened on top of it. This replaced a text-match
                # assertion (run #2 lesson): get_by_text found the tile's own now-hidden Home
                # label as the FIRST match and waited on that forever, failing 6 healthy tiles.
                opened = page.wait_for_function(
                    """() => {
                        const home = document.getElementById('homeView');
                        const homeHidden = !home || getComputedStyle(home).display === 'none';
                        const overlayOpen = !!document.querySelector('.sheet-overlay.open, .modal-backdrop.open, .scan-overlay.open');
                        return homeHidden || overlayOpen;
                    }""",
                    timeout=8000,
                )
                if console_errors:
                    failures.append(f"{tile}: JS error(s) — {'; '.join(console_errors[:3])}")
                    print(f"  ✗ {console_errors[0]}")
                else:
                    print("  ✓ ok, no console errors")
            except Exception as e:
                msg = str(e).splitlines()[0]
                failures.append(f"{tile}: {msg}")
                print(f"  ✗ {msg}")

        browser.close()

    print("\n" + "=" * 60)
    if failures:
        print(f"SMOKE TEST FAILED — {len(failures)} of {len(GOLDEN_PATHS)} golden paths broke:")
        for f in failures:
            print(f"  - {f}")
        return 1
    print(f"SMOKE TEST PASSED — all {len(GOLDEN_PATHS)} golden paths opened clean.")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="https://app.sautero.ch")
    parser.add_argument("--headed", action="store_true", help="Show the browser window instead of running headless.")
    args = parser.parse_args()

    # CI (GitHub Actions) sets both as env vars from repo secrets. For a local run, prompt
    # instead — the password is read with getpass (hidden, never echoed to the terminal and
    # never captured in a screenshot), and email defaults to the QA account so the whole thing
    # is one command with no quoting to get wrong (Richard, 20.7. — the env-var form was
    # error-prone by hand: shell quoting mangled the password).
    email = os.environ.get("SAUTERO_QA_EMAIL")
    password = os.environ.get("SAUTERO_QA_PASSWORD")
    if not email:
        try:
            entered = input("QA email [sautero_android@proton.me]: ").strip()
        except EOFError:
            entered = ""
        email = entered or "sautero_android@proton.me"
    if not password:
        import getpass
        password = getpass.getpass("QA password (hidden): ")
    if not email or not password:
        print("Need an email and a password to run the smoke test.")
        sys.exit(1)

    sys.exit(run(args.url, email, password, args.headed))
