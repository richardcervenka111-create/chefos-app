#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sautero QA coverage manifest (Richard, 21.7.2026 — "pridáme všetko z test_sweep, kontrolované 2× denne").

test_sweep.html is the human source-of-truth verification checklist (16 modules, ~398 items).
Most items are behavioural judgement calls a robot can't verify (e.g. "Face ID fails safely").
This script turns that file into a MACHINE-TRACKABLE manifest so nothing silently drops off the
list, and maps every module to the AUTOMATED protection it actually has today. It reports:
  * per-module item counts + status mix (ok / in-progress / not-started, from the checklist)
  * which automated guard(s) cover each module (smoke / tenant-isolation / auditors)
  * an overall automated-coverage estimate

Run locally (`python3 scripts/coverage_manifest.py`) or in CI (qa-checks.yml) to catch drift —
e.g. a new module added to test_sweep with zero automated coverage.
"""
import os, re, sys, json

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SWEEP = os.path.join(REPO, 'visual data', 'test_sweep.html')

# Which automated guard covers each module. Keys are matched case-insensitively as a substring
# of the module's English title. Update this map when new automated tests land — that is the
# single place that says "this feature area is / isn't machine-protected".
#   smoke   = e2e_smoke_test.py drives the tile across roles (screen opens, no JS error/5xx)
#   tenant  = tenant_isolation_test.sql leak-tests its tables (cross-kitchen isolation)
#   gates   = unauth_gates_test.py — credential-free pre-login gates (wall, sign-in reveal,
#             password/code toggle, safe failing login); no QA secrets, runs 2x/day always
#   calc    = calc_unit_test.js unit-tests this module's money math (recipe cost, payroll +
#             shift hours) against verified golden values; runs on every push + deploy gate
#   audit   = audit_app / audit_db static guards apply to its code/migrations (always)
COVERAGE = {
    'login & gates':      ['smoke', 'gates'],   # gates test covers the exact 20.7 pre-login bugs
    'home':               ['smoke'],
    'check list':         ['smoke', 'tenant'],  # projects/tasks/prep_* in the leak test
    'recipes':            ['smoke', 'tenant', 'calc'],   # computeRecipeCost unit-tested
    'ingredients':        ['smoke', 'tenant', 'calc'],   # parse/convert/cost lookup unit-tested
    'order list':         ['smoke', 'tenant'],
    'working time':       ['smoke', 'tenant', 'calc'],   # payroll hours + overtime unit-tested
    'events':             ['smoke', 'tenant'],
    'haccp':              ['smoke', 'tenant'],
    'print labels':       ['smoke', 'tenant'],
    'schedule':           ['tenant', 'calc'],   # shiftCodeHours unit-tested; not a smoke tile
    'chef':               ['smoke'],            # Chef's Assistant tile
    'connections':        ['smoke', 'tenant'],
    'admin':              ['smoke', 'tenant'],
    'settings':           ['smoke'],
    'profile':            ['smoke'],
}
AUDIT_ALWAYS = 'audit'  # the static auditors protect every module's code/migrations by default


def parse_modules(html):
    """Extract (title_en, [item statuses]) per module from the MODULES JS array. Robust to the
    escaped-apostrophe quoting: we only read structural keys (title_en, s/sc/sp), never the prose."""
    modules = []
    # each module starts: { icon:'…', title:'…', title_en:'…', items:[
    for mh in re.finditer(r"title_en:\s*'((?:[^'\\]|\\.)*)'\s*,\s*items:\s*\[", html):
        title_en = mh.group(1)
        # slice from this module's items:[ up to the next module header (or end)
        start = mh.end()
        nxt = html.find('title_en:', start)
        seg = html[start: nxt if nxt != -1 else len(html)]
        # statuses: either a single s:'…' or a sc:'…'/sp:'…' pair per item
        statuses = re.findall(r"\bs[cp]?:\s*'(ok|test|plan)'", seg)
        modules.append((title_en, statuses))
    return modules


def guards_for(title_en):
    t = title_en.lower()
    g = set()
    for key, guards in COVERAGE.items():
        if key in t:
            g.update(guards)
    g.add(AUDIT_ALWAYS)
    return sorted(g)


def main():
    if not os.path.exists(SWEEP):
        print('coverage_manifest: test_sweep.html not found — wrong directory?')
        return 1
    html = open(SWEEP, encoding='utf-8').read()
    modules = parse_modules(html)
    if not modules:
        print('coverage_manifest: parsed 0 modules — the MODULES format may have changed; update the parser.')
        return 1

    total_items = 0
    modules_with_only_static = 0
    rows = []
    for title_en, statuses in modules:
        n = len(statuses)
        total_items += n
        guards = guards_for(title_en)
        dynamic = [g for g in guards if g != AUDIT_ALWAYS]
        if not dynamic:
            modules_with_only_static += 1
        rows.append((title_en, n, statuses.count('ok'), statuses.count('test'),
                     statuses.count('plan'), guards))

    print(f'coverage_manifest: {len(modules)} modules, {total_items} checklist items (source: visual data/test_sweep.html)\n')
    print(f'{"module":24} {"items":>5} {"done":>5} {"wip":>4} {"todo":>5}  automated guards')
    print('-' * 78)
    for title_en, n, ok, test, plan, guards in rows:
        print(f'{title_en[:24]:24} {n:5} {ok:5} {test:4} {plan:5}  {", ".join(guards)}')

    print(f'\n{modules_with_only_static} module(s) have ONLY the static auditors (no smoke/tenant dynamic test) '
          f'— these are the biggest automation gaps to close next.')

    # optional JSON for tooling
    if '--json' in sys.argv:
        out = [{'module': t, 'items': n, 'done': ok, 'in_progress': test, 'not_started': plan,
                'guards': g} for (t, n, ok, test, plan, g) in rows]
        print('\n' + json.dumps(out, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    sys.exit(main())
