#!/usr/bin/env python3
"""Auto-maintained SECTIONS inside the existing Internal Docs (Richard, 22.7.26 — "potrebujem aby
sa editovali a updateovali aj TIETO dokumenty cez automatizácie").

A separate changelog doc wasn't enough — Richard wants the real docs (Plán, Biznis, …) to keep
themselves current. Fully auto-writing curated prose would wreck the investor-facing docs, so this
takes the safe, reliable half: it fills MACHINE sections marked in a doc with

    <!--AUTO:START:<generator>-->  … anything here is overwritten …  <!--AUTO:END:<generator>-->

from live sources (git, the scripts/ + workflows on disk), and never touches anything outside the
markers. Add a marker pair to any source doc and this keeps that region current on every commit.

Generators:
  robot_roster  — the live list of every test/guard/robot (scripts + GitHub workflows), so
                  Biznis → Automatizácie always reflects the automations that actually exist.

Commands:
  python3 scripts/docs_autosection.py           # fill every AUTO block in visual data/*.html
  python3 scripts/docs_autosection.py --check     # CI guard: fail if any AUTO block is out of date
"""
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VDIR = os.path.join(REPO, 'visual data')
SCRIPTS = os.path.join(REPO, 'scripts')
WORKFLOWS = os.path.join(REPO, '.github', 'workflows')

MARKER = re.compile(r'(<!--AUTO:START:([a-z_]+)-->)(.*?)(<!--AUTO:END:\2-->)', re.S)


def _docstring_first_line(path):
    """First non-empty line of a python module docstring, trimmed."""
    try:
        with open(path, encoding='utf-8') as fh:
            src = fh.read()
        m = re.search(r'^\s*(?:"""|\'\'\')(.*?)(?:"""|\'\'\')', src, re.S | re.M)
        if not m:
            return ''
        for line in m.group(1).splitlines():
            line = line.strip()
            if line:
                return line
    except Exception:
        pass
    return ''


def _esc(s):
    return (s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))


# ---------------------------------------------------------------- generator: robot_roster
# Which scripts are "robots" (tests/guards/generators), in a sensible reading order. Anything here
# that doesn't exist is skipped; any *_test.py / audit_*.py not listed is appended so a new robot
# can't silently go unlisted.
ROSTER_ORDER = [
    'audit_app.py', 'audit_db.py', 'ui_invariants.py', 'calc_unit_test.js',
    'tile_lock_test.py', 'ui_regression_test.py', 'unauth_gates_test.py', 'e2e_smoke_test.py',
    'docs_qa_test.py', 'coverage_manifest.py', 'health_report.py',
    'work_hours.py', 'docs_autofix.py', 'docs_changelog.py', 'docs_autosection.py',
]
# js/sql files have no python docstring — give them a one-liner here.
ROLE_OVERRIDE = {
    'calc_unit_test.js': 'Money-path unit tests (recipe cost, payroll + shift hours).',
    'tenant_isolation_test.sql': 'Cross-kitchen leak test — one kitchen can read none of another.',
}


def gen_robot_roster():
    present = {os.path.basename(p) for p in glob.glob(os.path.join(SCRIPTS, '*'))}
    ordered = [f for f in ROSTER_ORDER if f in present]
    extra = sorted(f for f in present
                   if (f.endswith('_test.py') or f.startswith('audit_')) and f not in ordered)
    files = ordered + extra

    rows = []
    for f in files:
        role = ROLE_OVERRIDE.get(f) or _docstring_first_line(os.path.join(SCRIPTS, f)) or '—'
        # keep it to one tidy clause: drop a parenthetical author/date note or a trailing sentence
        role = re.split(r'\s+\(|\s+—\s+|\.\s', role)[0].strip().rstrip('.,')
        rows.append(f'<li><code>{_esc(f)}</code> — {_esc(role)}.</li>')

    wf = []
    for p in sorted(glob.glob(os.path.join(WORKFLOWS, '*.yml'))):
        name = ''
        with open(p, encoding='utf-8') as fh:
            for line in fh:
                m = re.match(r'\s*name:\s*(.+)', line)
                if m:
                    name = m.group(1).strip().strip('"\'')
                    break
        wf.append(f'<li><code>{_esc(os.path.basename(p))}</code> — {_esc(name or "—")}</li>')

    total = len(files) + len(wf)
    return (
        f'\n<p style="color:var(--ink-dim); font-size:12px; margin:0 0 10px;" '
        f'data-sk="Živý zoznam — generovaný automaticky zo skutočných skriptov a workflowov ({total} spolu). '
        f'Nový robot sa sem doplní sám." '
        f'data-en="Live list — generated automatically from the actual scripts and workflows ({total} total). '
        f'A new robot is added here by itself.">Živý zoznam — generovaný automaticky zo skutočných skriptov a workflowov ({total} spolu). Nový robot sa sem doplní sám.</p>'
        f'\n<p style="font-size:12px; font-weight:700; margin:8px 0 4px; color:var(--accent);">scripts/</p>'
        f'\n<ul style="margin:0 0 12px; padding-left:18px; font-size:13px; line-height:1.6;">{"".join(rows)}</ul>'
        f'\n<p style="font-size:12px; font-weight:700; margin:8px 0 4px; color:var(--accent);">.github/workflows/</p>'
        f'\n<ul style="margin:0; padding-left:18px; font-size:13px; line-height:1.6;">{"".join(wf)}</ul>\n')


GENERATORS = {
    'robot_roster': gen_robot_roster,
}


def process(content):
    """Return (new_content, changed_bool). Fills every recognised AUTO block."""
    def repl(m):
        start, gen, end = m.group(1), m.group(2), m.group(4)
        if gen not in GENERATORS:
            return m.group(0)  # unknown generator — leave untouched
        return start + GENERATORS[gen]() + end
    new = MARKER.sub(repl, content)
    return new, (new != content)


def iter_docs():
    for p in sorted(glob.glob(os.path.join(VDIR, '*.html'))):
        yield p


def main():
    check = '--check' in sys.argv
    changed_files, drift = [], []
    for path in iter_docs():
        with open(path, encoding='utf-8') as fh:
            content = fh.read()
        if 'AUTO:START:' not in content:
            continue
        new, changed = process(content)
        if changed:
            if check:
                drift.append(os.path.basename(path))
            else:
                with open(path, 'w', encoding='utf-8') as fh:
                    fh.write(new)
                changed_files.append(os.path.basename(path))
    if check:
        if drift:
            print(f'docs_autosection: {len(drift)} doc(s) have STALE auto-sections: {", ".join(drift)}. '
                  f'Run python3 scripts/docs_autosection.py (the pre-commit hook does this).')
            return 1
        print('docs_autosection: all auto-sections current.')
        return 0
    if changed_files:
        print(f'docs_autosection: refreshed auto-sections in {", ".join(changed_files)}.')
    else:
        print('docs_autosection: auto-sections already current (or none present).')
    return 0


if __name__ == '__main__':
    sys.exit(main())
