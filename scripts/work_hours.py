#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sautero work-hours meter (Richard, 17.7.2026: "pridaj presný počet hodín koľko sme zatiaľ
pracovali a odteraz tento čas zaznamenávaj").

Derives real working time from git history — commits are the project's actual work trail.
Heuristic (standard "git hours" approach): consecutive commits ≤ 60 min apart form one
session; each session counts its span + 20 min lead-in for the work before the first commit.
Times in Europe/Zurich (Bern).

Git starts 2026-07-13 (engineering-discipline day). Days 8.–12.7. predate git, so they carry
an explicit ESTIMATE from the documented day logs (~8 h/day of shipped work) — always shown
with "~", never presented as measured.

MODES:
  (no flag)  prints the per-day table + the JS snippet (for humans).
  --write    git is the single source of truth: rewrites the `const WORK_HOURS = {...}` block in
             EVERY source doc that carries it (auto-discovered), so the hours can never drift
             between docs or go stale. Run in the pre-commit hook before build_docs, which then
             propagates the fresh block into the merged shells.
  --check    guard: fails (exit 1) if any doc's WORK_HOURS is missing a day git knows about, or
             disagrees with git. This is what makes "20.7/21.7 hours missing" impossible to ship.
"""
import subprocess
import datetime
import glob
import os
import re
import sys

GAP, LEAD = 3600, 20 * 60
BERN = datetime.timezone(datetime.timedelta(hours=2))
PRE_GIT_ESTIMATE = {  # documented in planning/tasklist day logs, no commit trail — estimates
    '2026-07-08': 8.0, '2026-07-09': 8.0, '2026-07-10': 8.0,
    '2026-07-11': 8.0, '2026-07-12': 8.0,
}
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Generated shells are rebuilt by build_docs from their sources — never write them directly.
GENERATED = {'produkt.html', 'plan.html', 'biznis.html', 'znacka.html', 'poznamky.html'}
MEASURED_FROM = '2026-07-13'


def measured_per_day():
    ts = sorted(int(x) for x in subprocess.check_output(['git', 'log', '--format=%ct']).split())
    sessions, start, prev = [], ts[0], ts[0]
    for t in ts[1:]:
        if t - prev > GAP:
            sessions.append((start, prev))
            start = t
        prev = t
    sessions.append((start, prev))
    per_day = {}
    for s, e in sessions:
        d = datetime.datetime.fromtimestamp(s, BERN).strftime('%Y-%m-%d')
        per_day[d] = per_day.get(d, 0) + (e - s) + LEAD
    return {d: round(v / 3600, 1) for d, v in per_day.items()}


def full_per_day():
    """Estimates (pre-git) + measured (git), one sorted dict — the single source of truth."""
    measured = measured_per_day()
    out = {}
    for d in sorted(set(list(PRE_GIT_ESTIMATE) + list(measured))):
        out[d] = measured[d] if d in measured else PRE_GIT_ESTIMATE[d]
    return out, measured


def render_block(data, measured):
    parts = []
    for d, h in data.items():
        parts.append(f"'{d}':{h}" + ('' if d in measured else ' /*odhad*/'))
    return 'const WORK_HOURS = { ' + ', '.join(parts) + ' };'


def source_files():
    files = []
    for f in sorted(glob.glob(os.path.join(REPO, 'visual data', '*.html'))):
        if os.path.basename(f) in GENERATED:
            continue
        if 'const WORK_HOURS = {' in open(f, encoding='utf-8', errors='replace').read():
            files.append(f)
    return files


def parse_hours(text):
    m = re.search(r'const WORK_HOURS = \{(.*?)\};', text, re.DOTALL)
    if not m:
        return {}
    return {d: float(h) for d, h in re.findall(r"'(\d{4}-\d\d-\d\d)'\s*:\s*([\d.]+)", m.group(1))}


def cmd_write():
    data, measured = full_per_day()
    block = render_block(data, measured)
    changed = []
    for f in source_files():
        text = open(f, encoding='utf-8').read()
        new = re.sub(r'const WORK_HOURS = \{.*?\};', block, text, count=1, flags=re.DOTALL)
        new = re.sub(r"const WORK_HOURS_MEASURED_FROM = '[^']*';",
                     f"const WORK_HOURS_MEASURED_FROM = '{MEASURED_FROM}';", new)
        if new != text:
            open(f, 'w', encoding='utf-8').write(new)
            changed.append(os.path.basename(f))
    print(f'work_hours: wrote git-derived WORK_HOURS into {len(changed)} doc(s): {", ".join(changed) or "(all already current)"}')
    return 0


def cmd_check():
    data, _ = full_per_day()
    problems = []
    files = source_files()
    for f in files:
        have = parse_hours(open(f, encoding='utf-8').read())
        missing = [d for d in data if d not in have]
        wrong = [d for d in data if d in have and abs(have[d] - data[d]) > 0.05]
        if missing or wrong:
            problems.append(f'{os.path.basename(f)}: missing {missing or "-"}, wrong {wrong or "-"}')
    if problems:
        print('work_hours CHECK FAILED — WORK_HOURS is stale/inconsistent with git:')
        for p in problems:
            print('  ✗ ' + p)
        print('  Fix: python3 scripts/work_hours.py --write  (then rebuild docs).')
        return 1
    print(f'work_hours: OK — {len(files)} doc(s) match git through {max(data)}.')
    return 0


def main():
    if '--write' in sys.argv:
        return cmd_write()
    if '--check' in sys.argv:
        return cmd_check()
    data, measured = full_per_day()
    total_measured = round(sum(measured.values()), 1)
    total_est = round(sum(PRE_GIT_ESTIMATE.values()), 1)
    print(f'measured (git, since 13.7.): {total_measured} h · pre-git estimate: ~{total_est} h · total: ~{round(total_measured + total_est, 1)} h')
    for d, h in data.items():
        print(f'{d}  {h} h  ' + ('(git)' if d in measured else '(estimate, pre-git)'))
    print('\n' + render_block(data, measured))
    print(f"const WORK_HOURS_MEASURED_FROM = '{MEASURED_FROM}';")


if __name__ == '__main__':
    sys.exit(main())
