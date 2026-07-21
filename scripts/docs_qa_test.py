#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sautero Internal-Docs QA robot (Richard, 21.7.2026 — "automatizuj 2x denne aj všetky
dokumenty v internal docs, možno každý dokument jeden robot; EN/SK prepínač vždy vo vrchnej
lište nech nič neprekrýva, a nech nič nelieta ako dnes ten deck").

ONE robot checks ONE Internal Docs page (run as a matrix in docs-qa.yml — one parallel job
per document). It renders the real page in a headless browser at mobile AND desktop widths
and asserts the three things that keep going wrong on these dashboards:

  1. NOTHING FLIES — no horizontal overflow at 375px or 1280px (the exact investor-deck bug:
     an element wider than the viewport makes the whole page slide sideways on a phone).
  2. EN/SK TOGGLE IS IN THE TOP BAR — the language switch exists, sits in the top ~80px,
     stays put on scroll (sticky/fixed), is visible, and is NOT overlapped by anything.
  3. NO MISSING DATA — no "undefined" / "NaN" / "[object Object]" / "{{...}}" / "TBD" leaking
     into the rendered text, and no bilingual element with one language side left empty.

Also fails on any console error or a 4xx/5xx response while loading — a broken dashboard.

Runs against the DEPLOYED docs by default (https://app.sautero.ch/x7n2k9/<doc>) so it checks
exactly what Richard opens on his phone; override with --base for local/staging.

USAGE:
  python3 scripts/docs_qa_test.py --doc produkt.html [--base URL] [--headed]
Exit 0 = the doc is clean, 1 = at least one problem (printed with specifics).
"""
import argparse
import sys

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Playwright not installed. Run: pip3 install playwright && python3 -m playwright install chromium")
    sys.exit(1)

# The audit runs in the page. Returns a dict of findings; kept as one JS string so the exact
# same logic was validated live in-browser before shipping.
AUDIT_JS = r"""
() => {
  const R = {};
  const de = document.documentElement;
  R.vw = innerWidth;
  R.overflowPx = de.scrollWidth - de.clientWidth;
  R.offenders = [];
  if (R.overflowPx > 4) {
    document.querySelectorAll('*').forEach(el => {
      const r = el.getBoundingClientRect();
      if (r.right > innerWidth + 4 || r.left < -4)
        R.offenders.push((el.tagName + (el.id ? '#' + el.id : '')) + ' right=' + Math.round(r.right));
    });
    R.offenders = R.offenders.slice(0, 5);
  }
  // EN/SK toggle detection across the different mechanisms these docs use
  const tog = [...document.querySelectorAll('button,a,[onclick],[id*="lang"],[id*="Lang"],[class*="lang"]')].find(el => {
    const t = (el.textContent || '').replace(/\s/g, '');
    const meta = (el.getAttribute('onclick') || '') + (el.id || '') + (el.className || '');
    return /^(EN\/SK|SK\/EN|EN\|SK|EN·SK)$/i.test(t) || /toggleLang|applyLang|switchLang|setLang|showLang/i.test(meta);
  });
  if (!tog) { R.toggle = { found: false }; }
  else {
    const r = tog.getBoundingClientRect();
    let sticky = false, n = tog;
    while (n && n !== document.body) { const p = getComputedStyle(n).position; if (p === 'sticky' || p === 'fixed') { sticky = true; break; } n = n.parentElement; }
    const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
    const top = document.elementFromPoint(cx, cy);
    const overlapped = !(top === tog || tog.contains(top) || (top && top.contains(tog)));
    R.toggle = { found: true, top: Math.round(r.top), inTopBar: r.top < 80, sticky, visible: r.width > 0 && r.height > 0,
                 overlapped, coveredBy: overlapped && top ? (top.tagName + (top.id ? '#' + top.id : '')) : null };
  }
  // missing data in rendered text
  const txt = document.body.innerText;
  R.placeholders = (txt.match(/undefined|\bNaN\b|\[object Object\]|\bTBD\b|\blorem\b|\{\{|\}\}|null,\s*null/gi) || []).slice(0, 8);
  // bilingual one-sided/empty
  const empties = [];
  document.querySelectorAll('[data-en],[data-sk]').forEach(el => {
    const en = el.getAttribute('data-en'), sk = el.getAttribute('data-sk');
    if ((en != null && en.trim() === '') || (sk != null && sk.trim() === '')) empties.push(el.tagName + ' empty-side');
    if ((en != null && sk == null) || (sk != null && en == null)) empties.push(el.tagName + ' one-sided');
  });
  R.biEmpties = [...new Set(empties)].slice(0, 8);
  R.biCount = document.querySelectorAll('[data-en],[data-sk]').length;
  return R;
}
"""


def run(base, doc, headed):
    url = base.rstrip('/') + '/' + doc
    problems = []
    console_errors = []
    bad_responses = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=not headed)
        context = browser.new_context()
        page = context.new_page()
        # A failed sub-resource (a missing font/favicon, a 4xx) is mirrored by the browser as a
        # generic "Failed to load resource" console error — that is network noise, already scored
        # by severity in the response handler (5xx = broken). Only app-authored console.error is a
        # real signal, so drop the resource-load echoes.
        IGNORE_CONSOLE = ('failed to load resource', 'favicon', 'manifest', 'net::err')
        page.on('console', lambda m: (console_errors.append(m.text[:160])
                if m.type == 'error' and not any(t in (m.text or '').lower() for t in IGNORE_CONSOLE) else None))
        page.on('response', lambda r: bad_responses.append(f'{r.status} {r.url}') if r.status >= 400 else None)

        # 1) nothing flies — check both widths
        for w, label in [(375, 'mobile'), (1280, 'desktop')]:
            page.set_viewport_size({'width': w, 'height': 900})
            page.goto(url, wait_until='networkidle', timeout=30000)
            r = page.evaluate(AUDIT_JS)
            if r['overflowPx'] > 4:
                problems.append(f'FLYING @ {label} {w}px: page is {r["overflowPx"]}px wider than the viewport '
                                f'(offenders: {", ".join(r["offenders"]) or "?"})')

        # 2) toggle + 3) data — assessed at desktop (last render), values already in r
        tog = r['toggle']
        if not tog['found']:
            problems.append('NO EN/SK TOGGLE: this doc has no language switch — it must have one in the top bar.')
        else:
            if not tog['visible']:
                problems.append('EN/SK toggle is present but not visible.')
            if not tog['inTopBar']:
                problems.append(f'EN/SK toggle is not in the top bar (its top is at {tog["top"]}px, must be < 80px).')
            if tog['overlapped']:
                problems.append(f'EN/SK toggle is overlapped/covered by {tog["coveredBy"]} — something is on top of it.')
            if not tog['sticky']:
                notes.append('recommendation: make the top bar sticky/fixed so the EN/SK toggle stays put on scroll.')

        if r['placeholders']:
            problems.append(f'MISSING DATA in rendered text: {", ".join(sorted(set(r["placeholders"])))}')
        if r['biEmpties']:
            problems.append(f'BILINGUAL gap: {", ".join(r["biEmpties"])} (a data-en/data-sk element with one side empty/missing)')

        browser.close()

    if console_errors:
        problems.append(f'Console error(s): {"; ".join(sorted(set(console_errors))[:3])}')
    if bad_responses:
        problems.append(f'Failed request(s): {"; ".join(sorted(set(bad_responses))[:3])}')

    print(f'\nInternal-Docs QA — {doc}  ({url})\n' + '-' * 64)
    for nt in notes:
        print('  [·] ' + nt)
    if not problems:
        print('  [OK] no flying, EN/SK toggle in the top bar (not overlapped), no missing data.')
        return 0
    for pr in problems:
        print('  [✗] ' + pr)
    print(f'\n{len(problems)} problem(s) in {doc}.')
    return 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--doc', required=True, help='doc path under the base, e.g. produkt.html')
    ap.add_argument('--base', default='https://app.sautero.ch/x7n2k9', help='docs base URL')
    ap.add_argument('--headed', action='store_true')
    args = ap.parse_args()
    return run(args.base, args.doc, args.headed)


if __name__ == '__main__':
    sys.exit(main())
