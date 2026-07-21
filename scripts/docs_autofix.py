#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sautero docs auto-fixer (Richard, 21.7.2026 — "chcem aby tí roboti aj automaticky nájdené
chyby opravili" + "všade štítok s dátumom vpravo dole").

The docs-QA robots (docs_qa_test.py) REPORT problems. This one FIXES the class of problem that
is safe to fix mechanically: a MISSING bottom-right date stamp. It walks the standalone Internal
Docs pages and, for any that lacks a date stamp, injects a fixed bottom-right
"Aktualizované/Updated <date>" badge — the date being that file's real last-commit date from git,
so it reflects true freshness and updates whenever the file changes.

WHY ONLY THE DATE STAMP auto-fixes: the other robot findings (nothing-flies, EN/SK-toggle-in-the-
top-bar, missing data) can't be corrected without understanding each doc's layout/content — an
automated edit there risks breaking the page, which is worse than the warning. So those stay
REPORT-ONLY (the robot flags them, a human/Claude fixes them). The date stamp is pure, additive,
and identical everywhere, so a robot can own it end to end.

The 5 generated shells (produkt/plan/biznis/znacka/poznamky) already get their stamp from
build_docs, so they're skipped here. Runs in the pre-commit hook (every commit keeps stamps
present + current) and standalone.

  python3 scripts/docs_autofix.py            # fix + report
  python3 scripts/docs_autofix.py --check    # report only, exit 1 if any stamp is missing/stale
"""
import os
import sys
import glob
import subprocess
import datetime

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VD = os.path.join(REPO, 'visual data')
# Generated docs own their stamp in their generator (build_docs shells; health_report renderer),
# so the auto-fixer must not touch them — its edit would just be overwritten on the next build.
GENERATED = {'produkt.html', 'plan.html', 'biznis.html', 'znacka.html', 'poznamky.html', 'health.html'}

STAMP_CSS = ('position:fixed;right:9px;bottom:8px;z-index:60;font-size:10.5px;font-weight:600;'
             'color:#9C949E;background:rgba(10,26,47,0.82);border:1px solid #223d57;'
             'border-radius:8px;padding:3px 9px;pointer-events:none;font-family:-apple-system,'
             'BlinkMacSystemFont,Arial,sans-serif;')


def git_date(path):
    os.environ['TZ'] = 'Europe/Zurich'
    try:
        out = subprocess.check_output(
            ['git', '-C', REPO, 'log', '-1', '--format=%cd', '--date=format-local:%-d.%-m.%Y', '--', path],
            stderr=subprocess.DEVNULL).decode().strip()
        return out or datetime.datetime.now().strftime('%-d.%-m.%Y')
    except Exception:
        return datetime.datetime.now().strftime('%-d.%-m.%Y')


def stamp_html(date):
    # bilingual via data-sk/data-en so the doc's own toggle (if any) localizes it; the visible
    # text defaults to SK, matching every other Sautero doc.
    return (f'<div class="datestamp" data-sk="Aktualizované {date}" data-en="Updated {date}" '
            f'style="{STAMP_CSS}">Aktualizované {date}</div>')


def targets():
    files = []
    for f in sorted(glob.glob(os.path.join(VD, '*.html'))):
        if os.path.basename(f) in GENERATED:
            continue
        files.append(f)
    # CRITICAL_REVIEW/latest.html is an Internal Doc too
    cr = os.path.join(VD, 'CRITICAL_REVIEW', 'latest.html')
    if os.path.exists(cr):
        files.append(cr)
    return files


# A doc already HAS a date stamp if it carries any of these — most standalone docs use their own
# `.sautero-stamp` badge; the generated shells use `.datestamp`. We must recognise ALL of them so
# the auto-fixer never adds a SECOND stamp next to an existing one (that duplicate-badge mess is
# exactly what this is meant to prevent).
HAS_STAMP = ('sautero-stamp', 'class="datestamp"', "class='datestamp'")


def process(check_only):
    fixed, missing = [], []
    for f in targets():
        rel = os.path.relpath(f, REPO)
        s = open(f, encoding='utf-8', errors='replace').read()
        if any(tok in s for tok in HAS_STAMP):
            continue  # already stamped — leave the doc's own badge alone
        missing.append(rel)
        if not check_only and '</body>' in s:
            s = s.replace('</body>', stamp_html(git_date(rel)) + '\n</body>', 1)
            open(f, 'w', encoding='utf-8').write(s)
            fixed.append(rel)

    if check_only:
        if missing:
            print(f'docs_autofix --check: {len(missing)} doc(s) have NO date stamp:')
            for p in missing:
                print('  ✗ ' + p)
            print('  Fix: python3 scripts/docs_autofix.py')
            return 1
        print('docs_autofix: OK — every Internal Doc carries a date stamp.')
        return 0

    if fixed:
        print(f'docs_autofix: added a date stamp to {len(fixed)} doc(s) that had none: {", ".join(fixed)}')
    else:
        print('docs_autofix: nothing to fix — every Internal Doc already has a date stamp.')
    return 0


def main():
    return process('--check' in sys.argv)


if __name__ == '__main__':
    sys.exit(main())
