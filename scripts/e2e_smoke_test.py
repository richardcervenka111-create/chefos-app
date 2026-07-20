#!/usr/bin/env python3
"""
Sautero end-to-end smoke test (Richard, 20.7.2026 — "urob to", follow-up to the manual
feature sweep taking too long to run by hand every time).

WHAT THIS IS: a "golden path" check, not full coverage. It logs in as one or more
dedicated QA accounts (one per ROLE — solo user, team member, kitchen admin, main admin)
and taps through every top-level Home tile for each, asserting two things per tile:
  1. the tile actually opened something (Home replaced by a view, or a sheet/overlay), and
  2. the browser threw NO JavaScript error while getting there.
That second check is the real value — most regressions in a single 23k-line HTML file
show up as a silent broken screen or a console error, and this catches that automatically
instead of needing a human to notice.

WHAT THIS IS NOT: it does not verify business logic (e.g. "does check-in correctly stop
the clock"), does not create/delete real data beyond what's unavoidable to open a screen,
and does not replace the manual sweep (visual data/test_sweep.html) — that stays the
source of truth for "does this feature behave correctly"; this is "is the app broken".

ACCOUNTS (each role's creds via env / GitHub Actions secrets; missing pairs are skipped
with a note, so roles can be added one at a time):
  SAUTERO_QA_EMAIL        / SAUTERO_QA_PASSWORD         — solo user, no team   (required)
  SAUTERO_QA_MEMBER_EMAIL / SAUTERO_QA_MEMBER_PASSWORD  — team member          (optional)
  SAUTERO_QA_ADMIN_EMAIL  / SAUTERO_QA_ADMIN_PASSWORD   — kitchen admin        (optional)
  SAUTERO_QA_MAIN_EMAIL   / SAUTERO_QA_MAIN_PASSWORD    — main/head admin      (optional)
All QA accounts are DEDICATED test accounts (Proton +aliases of the QA mailbox, e.g.
sautero_android+member@proton.me) — never Richard's real daily accounts: a CI robot must
not click around in an account someone lives in.

USAGE:
  python3 scripts/e2e_smoke_test.py [--url https://app.sautero.ch] [--headed]
Local runs with no env vars prompt for the base account only (password hidden via getpass).
"""
import argparse
import os
import sys

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Playwright not installed. Run: pip3 install playwright && python3 -m playwright install chromium")
    sys.exit(1)

# The 11 tiles every account has. Admin-role accounts additionally get the Admin tile.
# ("Team Meetings" is deliberately absent: for now it's an alert() placeholder, which the
# opened-something check can't observe.)
GOLDEN_PATHS = [
    "Working Time",
    "Recipes",
    "Ingredients",
    "Check List",
    "Order List",
    "Events",
    "HACCP",
    "Print Labels",
    "Chef's Assistant",
    "Connections",
    "Settings",
]

# label, email-env, password-env, extra tiles this role must also open
ROLES = [
    ("solo user (no team)",  "SAUTERO_QA_EMAIL",        "SAUTERO_QA_PASSWORD",        []),
    ("team member",          "SAUTERO_QA_MEMBER_EMAIL", "SAUTERO_QA_MEMBER_PASSWORD", []),
    ("kitchen admin",        "SAUTERO_QA_ADMIN_EMAIL",  "SAUTERO_QA_ADMIN_PASSWORD",  ["Admin"]),
    ("main admin",           "SAUTERO_QA_MAIN_EMAIL",   "SAUTERO_QA_MAIN_PASSWORD",   ["Admin"]),
]

TUTORIAL_MUTE_SCRIPT = """() => {
    const orig = Storage.prototype.getItem;
    Storage.prototype.getItem = function(k){
        if (k === 'chefos_tutorial_seen' || (typeof k === 'string' && k.indexOf('chefos_vtut_') === 0)) return '1';
        return orig.call(this, k);
    };
}"""

OPENED_SOMETHING_JS = """() => {
    const home = document.getElementById('homeView');
    const homeHidden = !home || getComputedStyle(home).display === 'none';
    const overlayOpen = !!document.querySelector('.sheet-overlay.open, .modal-backdrop.open, .scan-overlay.open');
    return homeHidden || overlayOpen;
}"""


def run_account(browser, url, label, email, password, extra_tiles):
    """Run the full tile sweep for one account in its own fresh browser context.
    Returns a list of failure strings ([] = the account passed)."""
    failures = []
    console_errors = []
    # A fresh context per account: clean localStorage/session so accounts can't bleed into
    # each other, and each starts exactly like a new device.
    context = browser.new_context()
    page = context.new_page()
    page.on("pageerror", lambda exc: console_errors.append(f"[pageerror] {exc}"))
    page.on("console", lambda msg: console_errors.append(f"[console.{msg.type}] {msg.text}") if msg.type == "error" else None)
    # A fresh browser has empty localStorage, so every first-run tutorial auto-opens and its
    # overlay blocks tile clicks. Report all tutorials as seen — test-harness concern only.
    page.add_init_script(TUTORIAL_MUTE_SCRIPT)

    # ?invite= bypasses the "coming soon" wall shown to any browser with zero invite context.
    login_url = url.rstrip("/") + "/?invite=e2e-smoke-test"
    print(f"\n═══ {label} — {email}")
    page.goto(login_url, wait_until="networkidle", timeout=30000)

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
        # Diagnostics: say WHY, not just "never reached Home".
        page.wait_for_timeout(1500)
        status = ""
        try:
            status = (page.locator("#loginStatus1").inner_text() or "").strip()
        except Exception:
            pass
        landed = page.evaluate(
            """() => {
                const ids = ['loginView','comingSoonView','privacyGateView','confidentialityGateView',
                             'passwordGateView','myProfileGateView','accountTypeGateView','teamGateView','homeView'];
                const vis = ids.filter(id => { const el=document.getElementById(id); return el && getComputedStyle(el).display !== 'none'; });
                return vis.join(',') || 'unknown';
            }"""
        )
        if status:
            msg = f'sign-in rejected — "{status}" (usually a wrong password)'
        elif landed and landed != "homeView":
            msg = f"signed in but stopped at: {landed} (finish that gate once by hand on this account)"
        else:
            msg = f"never reached Home (visible: {landed})"
        print(f"  ✗ LOGIN — {msg}")
        context.close()
        return [f"[{label}] login: {msg}"]
    print("  ✓ reached Home")

    for tile in GOLDEN_PATHS + extra_tiles:
        print(f"→ {tile}")
        try:
            # Reset to a clean Home before each tile (session persists across the reload) —
            # isolates every tile as its own check, no back-navigation fragility.
            page.goto(login_url, wait_until="domcontentloaded", timeout=20000)
            page.wait_for_selector("#homeView", state="visible", timeout=15000)
            console_errors.clear()  # watch the tile only, not the reload
            # has_text= (not :has-text()) so "Chef's Assistant"'s apostrophe can't break the selector.
            page.locator(".home-tile", has_text=tile).first.click(timeout=8000)
            page.wait_for_timeout(1200)  # let async loads settle
            page.wait_for_function(OPENED_SOMETHING_JS, timeout=8000)
            if console_errors:
                failures.append(f"[{label}] {tile}: JS error(s) — {'; '.join(console_errors[:3])}")
                print(f"  ✗ {console_errors[0]}")
            else:
                print("  ✓ ok, no console errors")
        except Exception as e:
            msg = str(e).splitlines()[0]
            failures.append(f"[{label}] {tile}: {msg}")
            print(f"  ✗ {msg}")

    context.close()
    return failures


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="https://app.sautero.ch")
    parser.add_argument("--headed", action="store_true", help="Show the browser window instead of running headless.")
    args = parser.parse_args()

    accounts = []
    for label, email_env, pw_env, extra in ROLES:
        email, password = os.environ.get(email_env), os.environ.get(pw_env)
        if email and password:
            accounts.append((label, email, password, extra))
        else:
            print(f"(skipping role '{label}' — {email_env}/{pw_env} not set)")

    if not accounts:
        # Local interactive run: prompt for the base account (password hidden — no shell
        # quoting to mangle, nothing captured in a screenshot).
        try:
            entered = input("QA email [sautero_android@proton.me]: ").strip()
        except EOFError:
            entered = ""
        email = entered or "sautero_android@proton.me"
        import getpass
        password = getpass.getpass("QA password (hidden): ")
        if not password:
            print("Need a password to run the smoke test.")
            return 1
        accounts.append(("solo user (no team)", email, password, []))

    all_failures = []
    total_paths = 0
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not args.headed)
        for label, email, password, extra in accounts:
            total_paths += len(GOLDEN_PATHS) + len(extra)
            all_failures += run_account(browser, args.url, label, email, password, extra)
        browser.close()

    print("\n" + "=" * 60)
    if all_failures:
        print(f"SMOKE TEST FAILED — {len(all_failures)} of {total_paths} checks broke across {len(accounts)} account(s):")
        for f in all_failures:
            print(f"  - {f}")
        return 1
    print(f"SMOKE TEST PASSED — {total_paths} golden paths clean across {len(accounts)} account(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
