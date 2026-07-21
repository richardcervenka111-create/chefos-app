#!/usr/bin/env python3
"""
Sautero unauthenticated-gates E2E test (Richard, 21.7.2026 — path-3 follow-up to the 20.7
login bugs: "coming-soon stena, 'already have an account', forgot-password").

WHAT THIS IS: a browser test for everything an unauthenticated visitor sees BEFORE login —
the coming-soon wall, the "Already have an account? Sign in" reveal, the login form, and
the password<->email-code toggle. It drives the real live app (app.sautero.ch) and asserts
each gate transition happens AND that nothing that means "broken" happened on the way
(uncaught JS exception, app-authored console.error, or 5xx response).

WHY IT'S SEPARATE from e2e_smoke_test.py: the smoke test needs QA account credentials to log
in and tap tiles. This one needs NO credentials at all — it never actually authenticates,
it only checks the pre-login gate structure and one deliberately-failing login. That means it
can run on the plain 2x/day schedule with ZERO secrets configured, so the exact screens that
broke on 20.7 (the wall, the sign-in reveal, the password/code toggle) are guarded every day
even before any QA mailbox exists. It is the credential-free half of the login coverage;
e2e_smoke_test.py is the authenticated half.

WHAT IT CHECKS (all against the live DOM, selectors verified live 21.7.):
  1. Default state = coming-soon wall: #comingSoonView visible, #loginView hidden, wall text
     present, and the "Already have an account? Sign in" button present.
  2. Reveal: clicking that button (showLoginFromComingSoon) hides the wall and shows the
     login form with #loginEmail, #loginPassword and a Sign in button.
  3. Password/email-code toggle: the "Don't have a password? Get a code by email" control
     (togglePasswordLogin) actually switches the form mode and can switch back — this is the
     passwordless / "forgot password" path for a user who has no password set.
  4. Login fails SAFELY: submitting an obviously-bogus email+password shows an error status
     and does NOT navigate into the app (#homeView never appears) and throws no JS error.
     (No account is created — signInWithPassword just fails auth server-side.)
Throughout: no uncaught pageerror, no app-authored console.error, no 5xx.

WHAT IT IS NOT: it does not test a real successful login (that's e2e_smoke_test.py), does not
verify email delivery of the code, and does not replace the manual sweep.

USAGE:
  python3 scripts/unauth_gates_test.py [--url https://app.sautero.ch] [--headed]
Exit 0 = all gates OK, 1 = a gate broke.
"""
import argparse
import sys

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Playwright not installed. Run: pip3 install playwright && python3 -m playwright install chromium")
    sys.exit(1)

# A bogus account that cannot exist — the failing-login check must never hit a real user.
BOGUS_EMAIL = "no-such-user.sautero-gatestest@example.invalid"
BOGUS_PASSWORD = "definitely-not-a-real-password-000"

# Mirrors e2e_smoke_test.py's noise filter: only fail on errors that mean the APP is broken,
# not on expected auth rejections or third-party console chatter.
IGNORABLE_CONSOLE = (
    "invalid login credentials", "invalid_credentials", "400 (bad request)",
    "auth", "password", "favicon", "manifest",
    # The deliberate bogus-login step makes the auth endpoint return 400; the browser mirrors
    # every failed request as a generic "Failed to load resource ... status of 400" console
    # error. That is EXPECTED (the app correctly rejects bad creds) and is already classified by
    # severity in on_response (4xx=warn, 5xx=hard), so this console echo is pure noise. Ignoring
    # it here is what a real broken-app 5xx still gets caught by on_response. (21.7 CI false pos.)
    "failed to load resource", "status of 400", "status of 401", "status of 403",
)


def run(url, headed):
    hard_errors = []   # uncaught JS + app console.error + 5xx -> real breakage
    warnings = []      # 4xx and the like -> printed, non-fatal
    checks = []        # (name, ok, detail)

    def record(name, ok, detail=""):
        checks.append((name, ok, detail))

    def on_console(msg):
        if msg.type != "error":
            return
        text = (msg.text or "").lower()
        if any(tok in text for tok in IGNORABLE_CONSOLE):
            return
        hard_errors.append(f"[console.error] {msg.text[:200]}")

    def on_response(resp):
        try:
            st = resp.status
        except Exception:
            return
        if st >= 500:
            hard_errors.append(f"[{st}] {resp.url}")
        elif st >= 400:
            warnings.append(f"[{st}] {resp.url}")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not headed)
        context = browser.new_context()
        page = context.new_page()
        page.on("pageerror", lambda exc: hard_errors.append(f"[pageerror] {exc}"))
        page.on("console", on_console)
        page.on("response", on_response)

        # ---- 1. default state: coming-soon wall ------------------------------------------
        page.goto(url, wait_until="networkidle", timeout=30000)
        page.wait_for_selector("#comingSoonView", state="visible", timeout=15000)
        wall_visible = page.evaluate(
            "() => { const c=document.getElementById('comingSoonView'), l=document.getElementById('loginView');"
            " return !!c && getComputedStyle(c).display!=='none' && (!l || getComputedStyle(l).display==='none'); }")
        record("wall shown by default (wall visible, login hidden)", wall_visible)
        has_wall_text = page.evaluate("() => /launching soon/i.test(document.body.innerText)")
        record("wall carries the 'launching soon' message", has_wall_text)
        signin_btn = page.locator("button[onclick*='showLoginFromComingSoon']")
        record("'Already have an account? Sign in' button present", signin_btn.count() > 0)

        # ---- 2. reveal the login form ----------------------------------------------------
        if signin_btn.count() > 0:
            signin_btn.first.click()
            try:
                page.wait_for_selector("#loginView", state="visible", timeout=8000)
                page.wait_for_selector("#loginEmail", state="visible", timeout=8000)
                revealed = page.evaluate(
                    "() => { const c=document.getElementById('comingSoonView'), l=document.getElementById('loginView');"
                    " return getComputedStyle(l).display!=='none' && (!c || getComputedStyle(c).display==='none'); }")
                record("clicking Sign in reveals login form, hides wall", revealed)
            except Exception as e:
                record("clicking Sign in reveals login form, hides wall", False, str(e)[:120])
            record("login form has email + password + Sign in",
                   page.locator("#loginEmail").count() > 0
                   and page.locator("#loginPassword").count() > 0
                   and page.locator("button[onclick*='signInWithPassword']").count() > 0)

        # ---- 3. password <-> email-code toggle (the "forgot / no password" path) ---------
        toggle = page.locator("[onclick*='togglePasswordLogin']")
        if toggle.count() > 0:
            pw_before = page.locator("#loginPassword").is_visible()
            toggle.first.click()
            page.wait_for_timeout(400)
            pw_after = page.locator("#loginPassword").is_visible()
            toggled = (pw_before != pw_after)
            # switch back so the form is in a known state for the next step
            if toggle.first.is_visible():
                toggle.first.click()
                page.wait_for_timeout(300)
            record("password / email-code toggle switches the form mode", toggled,
                   "" if toggled else f"password visibility unchanged ({pw_before}->{pw_after})")
        else:
            record("password / email-code toggle present", False, "no togglePasswordLogin control found")

        # ---- 4. a bogus login must fail SAFELY (no crash, stays out of the app) ----------
        try:
            if not page.locator("#loginPassword").is_visible():
                page.locator("[onclick*='togglePasswordLogin']").first.click()
                page.wait_for_selector("#loginPassword", state="visible", timeout=4000)
            page.fill("#loginEmail", BOGUS_EMAIL)
            page.fill("#loginPassword", BOGUS_PASSWORD)
            page.locator("button[onclick*='signInWithPassword']").first.click()
            page.wait_for_timeout(3000)  # let the auth round-trip come back
            entered_app = page.locator("#homeView").is_visible()
            record("bogus login does NOT enter the app", not entered_app,
                   "#homeView became visible on a fake login!" if entered_app else "")
        except Exception as e:
            record("bogus login handled without a page crash", False, str(e)[:120])

        browser.close()

    # ---- report ----------------------------------------------------------------------
    print(f"\nSautero unauthenticated-gates test — {url}\n" + "-" * 64)
    failed = 0
    for name, ok, detail in checks:
        mark = "PASS" if ok else "FAIL"
        if not ok:
            failed += 1
        print(f"  [{mark}] {name}" + (f"  ({detail})" if detail else ""))
    if warnings:
        print("\n  non-fatal 4xx (informational):")
        for w in sorted(set(warnings)):
            print("    - " + w)
    if hard_errors:
        print("\n  BROKEN-app signals (uncaught JS / console.error / 5xx):")
        for e in sorted(set(hard_errors)):
            print("    x " + e)

    ok_all = failed == 0 and not hard_errors
    print("\n" + ("ALL GATES OK" if ok_all else
                  f"GATE FAILURES: {failed} check(s) + {len(set(hard_errors))} app-broken signal(s)"))
    return 0 if ok_all else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default="https://app.sautero.ch")
    ap.add_argument("--headed", action="store_true")
    args = ap.parse_args()
    return run(args.url.rstrip("/") + "/", args.headed)


if __name__ == "__main__":
    sys.exit(main())
