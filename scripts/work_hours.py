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

Run during every doc-sync: prints the per-day table + the JS snippet to paste into
visual data/tasklist.html (WORK_HOURS block).
"""
import subprocess
import datetime

GAP, LEAD = 3600, 20 * 60
BERN = datetime.timezone(datetime.timedelta(hours=2))
PRE_GIT_ESTIMATE = {  # documented in planning/tasklist day logs, no commit trail — estimates
    '2026-07-08': 8.0, '2026-07-09': 8.0, '2026-07-10': 8.0,
    '2026-07-11': 8.0, '2026-07-12': 8.0,
}


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


def main():
    measured = measured_per_day()
    total_measured = round(sum(measured.values()), 1)
    total_est = round(sum(PRE_GIT_ESTIMATE.values()), 1)
    print(f'measured (git, since 13.7.): {total_measured} h · pre-git estimate: ~{total_est} h · total: ~{round(total_measured + total_est, 1)} h')
    rows = []
    for d in sorted(set(list(PRE_GIT_ESTIMATE) + list(measured))):
        if d in measured:
            rows.append(f"  '{d}': {measured[d]},")
            print(f'{d}  {measured[d]} h  (git)')
        else:
            rows.append(f"  '{d}': {PRE_GIT_ESTIMATE[d]},  // odhad — pred gitom")
            print(f'{d}  ~{PRE_GIT_ESTIMATE[d]} h  (estimate, pre-git)')
    print('\n// Paste into visual data/tasklist.html:')
    print('const WORK_HOURS = {')
    print('\n'.join(rows))
    print('};')
    print(f"const WORK_HOURS_MEASURED_FROM = '2026-07-13';")


if __name__ == '__main__':
    main()
