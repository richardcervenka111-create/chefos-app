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

        # ?invite= bypasses the "coming soon" wall shown to any browser with zero invite
        # context (app_config.coming_soon_enabled, app/index.html's init()) — without it a
        # fresh headless browser never even reaches the login form.
        login_url = url.rstrip("/") + "/?invite=e2e-smoke-test"
        print(f"→ Opening {login_url}")
        page.goto(login_url, wait_until="networkidle", timeout=30000)

        print(f"→ Signing in as {email}")
        page.wait_for_selector("#loginEmail", state="visible", timeout=15000)
        page.fill("#loginEmail", email)
        page.click("#passwordLoginToggleLink")  # password field starts hidden — magic-link is the default flow
        page.wait_for_selector("#loginPassword", state="visible", timeout=5000)
        page.fill("#loginPassword", password)
        page.click("#loginPasswordBlock button:has-text('Sign in')")  # not the (hidden) Face ID button, which also matches "Sign in"
        try:
            page.wait_for_selector("#homeView", state="visible", timeout=15000)
        except Exception:
            print("FAIL: never reached Home after sign-in — check the QA account has a password set and has finished onboarding.")
            browser.close()
            return 1
        print("  ✓ reached Home")

        for step in GOLDEN_PATHS:
            console_errors.clear()
            tile = step["tile"]
            print(f"→ {tile}")
            try:
                page.click(f".home-tile:has-text('{tile}')", timeout=8000)
                page.wait_for_timeout(1200)  # let async loads settle
                if step["expect_text"]:
                    page.wait_for_selector(f"text={step['expect_text']}", timeout=8000)
                if console_errors:
                    failures.append(f"{tile}: JS error(s) — {'; '.join(console_errors[:3])}")
                    print(f"  ✗ {console_errors[0]}")
                else:
                    print("  ✓ ok, no console errors")
            except Exception as e:
                failures.append(f"{tile}: {e}")
                print(f"  ✗ {e}")
            finally:
                # Best-effort return to Home for the next tile — tolerate either a back
                # icon or a full reload if a tile leaves us somewhere unexpected.
                try:
                    if page.locator(BACK_ICON_SELECTOR).count():
                        page.locator(BACK_ICON_SELECTOR).first.click(timeout=3000)
                        page.wait_for_selector("#homeView", state="visible", timeout=5000)
                    elif not page.locator("#homeView").is_visible():
                        page.goto(url, wait_until="networkidle", timeout=15000)
                        page.wait_for_selector("#homeView", state="visible", timeout=15000)
                except Exception:
                    page.goto(url, wait_until="networkidle", timeout=15000)

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

    email = os.environ.get("SAUTERO_QA_EMAIL")
    password = os.environ.get("SAUTERO_QA_PASSWORD")
    if not email or not password:
        print("Set SAUTERO_QA_EMAIL and SAUTERO_QA_PASSWORD environment variables first (see the docstring at the top of this file).")
        sys.exit(1)

    sys.exit(run(args.url, email, password, args.headed))
