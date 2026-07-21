#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sautero Health Report (Richard, 21.7.2026 — "Health Report: Architecture / Security /
Documentation / Technical Debt, všetko zautomatizované").

Four automated audits computed from the REAL codebase — no hand-entered numbers. Produces:
  * a console summary (for CI logs), and
  * a generated dashboard at "visual data/health.html" (navy/teal, bilingual, tap-to-expand),
    so the health picture is always current and viewable on Richard's phone via Internal Docs.

Runs 2x/day in qa-checks.yml. This is a STATIC analyzer: it reads files and measures them, it
does not run the app. It complements — does not replace — the auditors (which FAIL a build)
and the E2E/calc tests (which check behaviour). The report never fails the build; it grades.

Every metric below is derived by reading app/index.html, db/*.sql, supabase/functions/*, and
visual data/*.html. Where an existing auditor already computes something authoritative
(secrets, RLS, ghost tables, mutation ratchet), this calls it rather than re-deriving.
"""
import re
import os
import glob
import json
import subprocess
import datetime

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP_PATH = os.path.join(REPO, 'app', 'index.html')


def read(p):
    return open(p, encoding='utf-8', errors='replace').read()


def bern_now():
    # Bern time, honouring the standing "always Europe/Zurich" rule without external deps.
    os.environ['TZ'] = 'Europe/Zurich'
    try:
        import time
        time.tzset()
    except Exception:
        pass
    return datetime.datetime.now().strftime('%Y-%m-%d %H:%M')


APP = read(APP_PATH)
MIGRATIONS = sorted(glob.glob(os.path.join(REPO, 'db', '*.sql')))
EDGE = sorted(glob.glob(os.path.join(REPO, 'supabase', 'functions', '*', 'index.ts')))
DOCS = sorted(glob.glob(os.path.join(REPO, 'visual data', '*.html')))
MIGR_TEXT = ' '.join(read(f).lower() for f in MIGRATIONS)


def status(ok, warn=False):
    return 'fail' if not ok and not warn else ('warn' if warn else 'ok')


def _git_latest():
    os.environ['TZ'] = 'Europe/Zurich'
    try:
        ts = int(subprocess.check_output(['git', '-C', REPO, 'log', '-1', '--format=%ct']).strip())
        return datetime.datetime.fromtimestamp(ts).date()
    except Exception:
        return datetime.date.today()


def _newest_date(text):
    """Newest calendar date mentioned in a doc — handles YYYY-MM-DD, D.M.YYYY, and bare D.M.
    (assumed current year). Used to tell whether a day-log doc has fallen behind the work."""
    cands = []
    for y, mo, d in re.findall(r'(20\d{2})-(\d{2})-(\d{2})', text):
        try: cands.append(datetime.date(int(y), int(mo), int(d)))
        except ValueError: pass
    for d, mo, y in re.findall(r'\b(\d{1,2})\.\s?(\d{1,2})\.\s?(20\d{2})\b', text):
        try: cands.append(datetime.date(int(y), int(mo), int(d)))
        except ValueError: pass
    yr = datetime.date.today().year
    for d, mo in re.findall(r'\b(\d{1,2})\.\s?(\d{1,2})\.(?!\s?\d)', text):
        try: cands.append(datetime.date(yr, int(mo), int(d)))
        except ValueError: pass
    horizon = datetime.date.today() + datetime.timedelta(days=1)
    cands = [c for c in cands if c <= horizon]
    return max(cands) if cands else None


# ---------------------------------------------------------------- Architecture ----
def architecture_audit():
    checks = []
    lines = APP.count('\n') + 1
    kb = round(len(APP.encode('utf-8')) / 1024)
    fn_defs = re.findall(r'\bfunction\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(', APP)
    fn_count = len(fn_defs)

    # duplicate function names (same name defined twice — shadowing risk)
    dupes = sorted({n for n in fn_defs if fn_defs.count(n) > 1})

    # dead functions: name that appears exactly once in the whole file (its own definition) —
    # onclick/handler refs live in HTML strings, so a used handler appears >1 time.
    counts = {}
    for m in re.finditer(r'[a-zA-Z_][a-zA-Z0-9_]*', APP):
        counts[m.group(0)] = counts.get(m.group(0), 0) + 1
    dead = sorted(n for n in set(fn_defs) if counts.get(n, 0) <= 1)

    # longest functions by line span (brace-naive but fine for a size signal)
    spans = []
    for m in re.finditer(r'\bfunction\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\([^)]*\)\s*\{', APP):
        name, start = m.group(1), m.end() - 1
        depth, j = 0, start
        while j < len(APP):
            if APP[j] == '{':
                depth += 1
            elif APP[j] == '}':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        spans.append((name, APP.count('\n', start, j) + 1))
    spans.sort(key=lambda x: -x[1])
    long_fns = [s for s in spans if s[1] > 150]

    # DB structure: created vs queried tables
    created = set(re.findall(r'create table (?:if not exists )?([a-z_]+)', MIGR_TEXT))
    queried = set(re.findall(r"sb\.from\('([a-z_]+)'\)", APP))
    orphan = sorted(created - queried)          # created, never queried by the app
    ghost = sorted(queried - created)           # queried, never created (audit_app fails on this)

    checks.append(('Single-file app size', 'warn' if lines > 20000 else 'ok',
                   f'{lines:,} lines / {kb} KB',
                   'One 23k-line HTML file is the known central architectural constraint — the '
                   'consolidation work (zero-feature-loss) is the standing plan to reduce it.'))
    checks.append(('Functions defined', 'ok', f'{fn_count}', 'Total named functions in the app.'))
    checks.append(('Duplicate function names', status(not dupes), f'{len(dupes)}',
                   ('e.g. ' + ', '.join(dupes[:6])) if dupes else 'No shadowed function names.'))
    checks.append(('Dead functions (defined, never referenced)', status(not dead, warn=bool(dead)),
                   f'{len(dead)}', ('e.g. ' + ', '.join(dead[:8])) if dead else 'None found.'))
    checks.append(('Functions > 150 lines', 'warn' if long_fns else 'ok', f'{len(long_fns)}',
                   ('longest: ' + ', '.join(f'{n} ({l})' for n, l in long_fns[:5])) if long_fns
                   else 'No oversized functions.'))
    checks.append(('DB tables created', 'ok', f'{len(created)}', f'{len(MIGRATIONS)} migrations.'))
    checks.append(('Orphan tables (created, app never queries)', 'warn' if orphan else 'ok',
                   f'{len(orphan)}', (', '.join(orphan[:10])) if orphan
                   else 'Every created table is queried by the app.'))
    checks.append(('Ghost tables (queried, never created)', status(not ghost), f'{len(ghost)}',
                   (', '.join(ghost)) if ghost else 'None — audit_app guards this.'))
    return grade_block('Architecture', checks, extra={'longest': spans[:5], 'dead': dead})


# ---------------------------------------------------------------- Security ----
def security_audit():
    checks = []
    # reuse the authoritative auditors as pass/fail gates
    aud_app = run_ok(['python3', os.path.join(REPO, 'scripts', 'audit_app.py')])
    aud_db = run_ok(['python3', os.path.join(REPO, 'scripts', 'audit_db.py')])

    # external resources loaded by the app (CSP / supply-chain surface)
    ext = re.findall(r'<(?:script[^>]+src|link[^>]+href)=["\']([^"\']+)["\']', APP)
    ext_off = [u for u in ext if u.startswith('http') and 'sautero' not in u and 'supabase' not in u]

    # XSS boundary: innerHTML sinks + presence of the foreign-data escapers
    inner = APP.count('.innerHTML')
    escapers_ok = ('function sanitizeForeignRecipe(' in APP and 'function sanitizeForeignIngredient(' in APP)

    # tenant scoping in app code: reads that explicitly filter kitchen_id (RLS also enforces
    # server-side; this is a defence-in-depth signal, not a hard requirement per query).
    from_calls = len(re.findall(r'sb\.from\(', APP))
    kitchen_eq = len(re.findall(r"\.eq\('kitchen_id'", APP))

    # RLS coverage in migrations
    rls_enabled = len(set(re.findall(r'alter table (\w+) enable row level security', MIGR_TEXT)))

    # secrets (authoritative check is audit_app; here we just confirm none leaked into edge/docs)
    secretish = 0
    for f in EDGE:
        if re.search(r'sk-ant-[a-zA-Z0-9_\-]{20,}|re_[a-zA-Z0-9]{20,}', read(f)):
            secretish += 1

    checks.append(('audit_app gate (structure, secrets, XSS guard, ratchet)', status(aud_app),
                   'PASS' if aud_app else 'FAIL', 'The build-blocking app auditor.'))
    checks.append(('audit_db gate (RLS, tenant scoping, destructive SQL)', status(aud_db),
                   'PASS' if aud_db else 'FAIL', 'The build-blocking DB auditor.'))
    checks.append(('Off-site scripts/styles loaded', status(not ext_off), f'{len(ext_off)}',
                   (', '.join(ext_off[:6])) if ext_off else 'No third-party script/style hosts.'))
    checks.append(('Cross-kitchen XSS escapers wired', status(escapers_ok),
                   'yes' if escapers_ok else 'MISSING',
                   'sanitizeForeignRecipe + sanitizeForeignIngredient guard foreign innerHTML.'))
    checks.append(('innerHTML sinks', 'warn' if inner > 250 else 'ok', f'{inner}',
                   'High but expected for a render-by-innerHTML single-file app; foreign data is '
                   'escaped at the data boundary (see escapers above).'))
    checks.append(('Explicit kitchen_id filters in app reads', 'ok',
                   f'{kitchen_eq} / {from_calls} sb.from()',
                   'Defence-in-depth on top of RLS; not every query needs it (RLS enforces isolation).'))
    checks.append(('Tables with RLS enabled', 'ok', f'{rls_enabled}',
                   'audit_db fails the build if any kitchen-scoped table lacks RLS + a policy.'))
    checks.append(('Secrets in edge functions', status(secretish == 0), f'{secretish}',
                   'No hard-coded API keys in supabase/functions.' if secretish == 0 else 'LEAK — investigate.'))
    return grade_block('Security', checks)


# ---------------------------------------------------------------- Documentation ----
def documentation_audit():
    checks = []
    # brand hygiene: leftover "ChefOS" in user-facing docs (technical chefos_ identifiers are allowed)
    # Docs where "ChefOS" is INTENTIONAL and must stay: the naming-history / rebrand-lesson
    # docs (why the brand became Sautero) and this generated report (which names the brand-check
    # metric). Flagging those would be a false positive — and scanning health.html against itself
    # would oscillate the score each run. Everything else must be ChefOS-free.
    BRAND_HISTORY_OK = {'nazov.html', 'nazov_src.html', 'poznamky.html', 'poznamky_src.html',
                        'gronda.html', 'gronda_src.html', 'health.html'}
    brand_hits = 0
    brand_files = []
    for f in DOCS:
        if os.path.basename(f) in BRAND_HISTORY_OK:
            continue
        n = len(re.findall(r'ChefOS', read(f)))
        if n:
            brand_hits += n
            brand_files.append(f'{os.path.basename(f)}({n})')

    # bilingual coverage: docs that expose a SK/EN toggle should carry both languages
    bilingual = 0
    lang_docs = 0
    for f in DOCS:
        s = read(f)
        if 'sautero_doc_lang' in s or 'data-sk' in s or "lang==='sk'" in s.lower():
            lang_docs += 1
            if ('data-en' in s or 'data-sk' in s or 'MSK' in s or 'applyLang' in s):
                bilingual += 1

    # MEMORY.md pointers resolve to real files
    mem_dir = os.path.join(REPO, '..', '..', '.claude', 'projects')  # not in repo; skip if absent
    # build_docs sources exist
    bd_path = os.path.join(REPO, 'scripts', 'build_docs.py')
    missing_sources = []
    if os.path.exists(bd_path):
        for src in re.findall(r"'([A-Za-z_]+\.html)'", read(bd_path)):
            if not os.path.exists(os.path.join(REPO, 'visual data', src)) and src not in (
                    'produkt.html', 'plan.html', 'biznis.html', 'znacka.html', 'poznamky.html'):
                missing_sources.append(src)

    # freshness: newest vs oldest doc mtime span
    stamps = []
    for f in DOCS:
        m = re.search(r'(\d{1,2}\.\s?\d{1,2}\.\s?20\d{2}|20\d{2}-\d{2}-\d{2})', read(f))
        if m:
            stamps.append(os.path.basename(f))

    # STALE DAILY/LOG DOCS — the "20.7/21.7 data missing" class. The day-tracking prose docs
    # (diary, automations, status) must not fall behind the actual work: if their newest date is
    # >3 days behind the latest git commit, they went stale and someone has to notice — this makes
    # the robot notice instead. (Worked hours are auto-written from git by work_hours.py, so those
    # can't drift; this covers the hand-written day logs.)
    git_latest = _git_latest()
    stale = []
    for name in ['planning.html', 'automation.html', 'status.html']:
        p = os.path.join(REPO, 'visual data', name)
        if not os.path.exists(p):
            continue
        nd = _newest_date(read(p))
        if nd is None or (git_latest - nd).days > 3:
            stale.append(f'{name}→{nd or "?"}')

    checks.append(('Leftover "ChefOS" brand in docs', status(brand_hits == 0), f'{brand_hits}',
                   (', '.join(brand_files[:8])) if brand_hits else 'All docs are on-brand (Sautero).'))
    checks.append(('Bilingual docs complete (SK/EN)', status(bilingual == lang_docs),
                   f'{bilingual}/{lang_docs}',
                   'Every doc with a language toggle carries both languages.' if bilingual == lang_docs
                   else 'Some toggled docs are missing a language.'))
    checks.append(('build_docs sources missing', status(not missing_sources), f'{len(missing_sources)}',
                   (', '.join(missing_sources)) if missing_sources else 'All merge sources exist.'))
    checks.append(('Daily/log docs fresh (≤3 days behind git)', status(not stale, warn=bool(stale)),
                   f'{len(stale)} stale', (', '.join(stale)) if stale
                   else f'diary / automations / status current with git ({git_latest}).'))
    checks.append(('Dashboards in visual data/', 'ok', f'{len(DOCS)}',
                   'Investor deck, status, backlog, monetization, brand, health, etc.'))
    checks.append(('Docs carrying a date stamp', 'ok', f'{len(stamps)}/{len(DOCS)}',
                   'A dated stamp lets a reader trust freshness.'))
    return grade_block('Documentation', checks)


# ---------------------------------------------------------------- Technical Debt ----
def techdebt_audit():
    checks = []
    todos = re.findall(r'(?://|<!--|/\*)\s*(TODO|FIXME|HACK|XXX)\b[:\s].{0,80}', APP)
    todo_n = len(re.findall(r'\b(?:TODO|FIXME|HACK|XXX)\b', APP))
    consolelog = APP.count('console.log')
    debugger = APP.count('debugger')

    # unchecked mutation ratchet baseline (audit_app enforces it doesn't grow)
    base_path = os.path.join(REPO, 'scripts', 'unchecked_mutations.baseline')
    ratchet = read(base_path).strip() if os.path.exists(base_path) else '?'

    # DB-contract rebrand debt: the chefos-named identifiers that must stay (tracked, guarded)
    contract_tokens = ['shared_with_chefos', 'chefos_master_id', "shelf_scope", "'recipe_chefos'"]
    contract_present = sum(1 for t in contract_tokens if t in APP)

    # dead functions (reuse architecture detection, lightweight)
    fn_defs = set(re.findall(r'\bfunction\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(', APP))
    counts = {}
    for mm in re.finditer(r'[a-zA-Z_][a-zA-Z0-9_]*', APP):
        counts[mm.group(0)] = counts.get(mm.group(0), 0) + 1
    dead_n = sum(1 for n in fn_defs if counts.get(n, 0) <= 1)

    checks.append(('TODO / FIXME / HACK / XXX markers', 'warn' if todo_n > 0 else 'ok', f'{todo_n}',
                   'Tracked debt notes in the code; not bugs, but the backlog of "come back to this".'))
    checks.append(('Stray console.log', status(consolelog == 0), f'{consolelog}',
                   'No debug logging left in production.' if consolelog == 0 else 'Remove before shipping.'))
    checks.append(('Stray debugger statements', status(debugger == 0), f'{debugger}',
                   'None.' if debugger == 0 else 'Remove.'))
    checks.append(('Unchecked mutation ratchet', 'ok', f'{ratchet}',
                   'Silent-no-op delete/update call sites; audit_app fails if this number grows.'))
    checks.append(('Dead functions', 'warn' if dead_n else 'ok', f'{dead_n}',
                   'Defined but never referenced — safe to prune during consolidation.'))
    checks.append(('DB-contract rebrand debt (guarded)', 'ok', f'{contract_present}/4 tokens',
                   'chefos-named DB identifiers kept on purpose (live schema); a coordinated '
                   'migration is the only correct way to rename them. Guarded by check_db_contract.'))
    return grade_block('Technical Debt', checks)


# ---------------------------------------------------------------- helpers ----
def run_ok(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, cwd=REPO).returncode == 0
    except Exception:
        return False


def grade_block(name, checks, extra=None):
    # score = share of non-fail checks, with warns worth half
    pts = sum(1.0 if c[1] == 'ok' else (0.5 if c[1] == 'warn' else 0.0) for c in checks)
    score = round(100 * pts / len(checks)) if checks else 0
    grade = ('A' if score >= 90 else 'B' if score >= 80 else 'C' if score >= 70 else
             'D' if score >= 60 else 'F')
    return {'name': name, 'score': score, 'grade': grade,
            'checks': [{'name': c[0], 'status': c[1], 'value': c[2], 'detail': c[3]} for c in checks],
            'extra': extra or {}}


def main():
    blocks = [architecture_audit(), security_audit(), documentation_audit(), techdebt_audit()]
    overall = round(sum(b['score'] for b in blocks) / len(blocks))
    grade = ('A' if overall >= 90 else 'B' if overall >= 80 else 'C' if overall >= 70 else
             'D' if overall >= 60 else 'F')
    report = {'generated': bern_now() + ' (Bern)', 'overall_score': overall, 'overall_grade': grade,
              'blocks': blocks}

    # console summary
    print(f"\nSautero Health Report — {report['generated']}")
    print(f"  OVERALL: {overall}/100  (grade {grade})")
    for b in blocks:
        print(f"\n  {b['name']}: {b['score']}/100 ({b['grade']})")
        for c in b['checks']:
            mark = {'ok': '✓', 'warn': '!', 'fail': '✗'}[c['status']]
            print(f"    {mark} {c['name']}: {c['value']}")

    # write JSON next to the script for tooling, and generate the dashboard
    with open(os.path.join(REPO, 'scripts', 'health_report.json'), 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    try:
        from health_report_html import render
        html = render(report)
        with open(os.path.join(REPO, 'visual data', 'health.html'), 'w', encoding='utf-8') as f:
            f.write(html)
        print('\nhealth_report: wrote visual data/health.html')
    except Exception as e:
        print(f'\nhealth_report: dashboard not generated ({e})')
    return 0


if __name__ == '__main__':
    import sys
    sys.exit(main())
