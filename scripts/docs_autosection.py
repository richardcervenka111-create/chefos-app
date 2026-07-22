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


def _feature_counts():
    try:
        c = open(os.path.join(VDIR, 'feature_status.html'), encoding='utf-8').read()
    except Exception:
        return {}
    out = {}
    for st in re.findall(r"status:'(ok|test|plan|build)'", c):
        out[st] = out.get(st, 0) + 1
    return out


def _robot_count():
    present = {os.path.basename(p) for p in glob.glob(os.path.join(SCRIPTS, '*'))}
    scripts = {f for f in ROSTER_ORDER if f in present}
    scripts |= {f for f in present if f.endswith('_test.py') or f.startswith('audit_')}
    return len(scripts) + len(glob.glob(os.path.join(WORKFLOWS, '*.yml')))


def gen_current_state():
    """A live 'where we stand today' panel: feature counts, locked tiles, robot count, and the
    last few changes — all derived, refreshed every commit. Marker lives in status.html (Plán → Teraz)."""
    import json
    try:
        from docs_changelog import git_log
        recent = git_log()[:6]
    except Exception:
        recent = []
    try:
        reg = json.load(open(os.path.join(SCRIPTS, 'locked_tiles.json'), encoding='utf-8'))
        locked = reg.get('locked', [])
    except Exception:
        locked = []
    fc = _feature_counts()
    total = sum(fc.values())
    live = fc.get('ok', 0)
    robots = _robot_count()

    def stat(num, sk, en):
        return (f'<div style="flex:1 1 120px;background:var(--paper,#0F2340);border:1px solid var(--rule,rgba(52,247,215,.16));'
                f'border-radius:12px;padding:12px 14px;"><div style="font-family:Georgia,serif;font-size:26px;'
                f'color:var(--accent,#34F7D7);line-height:1;font-variant-numeric:tabular-nums;">{num}</div>'
                f'<div style="font-size:11.5px;color:var(--ink-dim,#9DB2BD);margin-top:5px;" '
                f'data-sk="{sk}" data-en="{en}">{sk}</div></div>')

    stats = (
        stat(f'{live} / {total}', 'funkcií naživo', 'features live')
        + stat(str(robots), 'automatických robotov', 'automated robots')
        + stat(str(len(locked)), 'zamknutých dlaždíc', 'locked tiles')
        + stat(', '.join(locked) or '—', 'čo je zamknuté', 'what is locked')
    )
    items = ''.join(
        f'<li style="padding:5px 0;border-bottom:1px solid rgba(255,255,255,.05);font-size:12.5px;color:var(--ink,#EAF2F5);">'
        f'<span style="font-family:ui-monospace,Menlo,monospace;color:var(--accent,#34F7D7);font-size:11px;margin-right:8px;">{_esc(d)}</span>'
        f'{_esc(s)}</li>'
        for (_h, d, s) in recent)

    return (
        f'\n<p style="color:var(--ink-dim,#9DB2BD);font-size:12px;margin:0 0 12px;" '
        f'data-sk="Živý stav — čísla aj posledné zmeny sa generujú automaticky pri každom commite." '
        f'data-en="Live state — the numbers and the latest changes are generated automatically on every commit.">'
        f'Živý stav — čísla aj posledné zmeny sa generujú automaticky pri každom commite.</p>'
        f'\n<div style="display:flex;flex-wrap:wrap;gap:10px;margin:0 0 16px;">{stats}</div>'
        f'\n<p style="font-size:12px;font-weight:700;color:var(--accent,#34F7D7);margin:0 0 4px;" '
        f'data-sk="Posledné zmeny" data-en="Latest changes">Posledné zmeny</p>'
        f'\n<ul style="list-style:none;margin:0;padding:0;">{items}</ul>\n')


GENERATORS = {
    'robot_roster': gen_robot_roster,
    'current_state': gen_current_state,
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
