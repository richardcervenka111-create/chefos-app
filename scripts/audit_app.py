#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ChefOS app auditor — the permanent guard for the single-file bug classes.

Checks app/index.html (and every other app/ + "visual data/" HTML file) for the
exact failure classes that have actually bitten this project:

  1. Structural imbalance — {} braces, <div>, <details>, <section> pairs, and
     stray control characters (a literal \\x01 byte once broke a regex here).
  2. Dead buttons — every onclick="fn(...)" must have a matching function
     definition in the same file.
  3. Ghost tables — every sb.from('x') in app code must exist in some db/*.sql
     migration (create table / alter table), so code can't reference a table
     nobody ever created.
  4. Secret patterns — real Anthropic keys, service_role JWTs, Resend live keys.
     (The Supabase publishable key is public by design and allowed.)
  5. Unchecked-mutation ratchet — Supabase .delete()/.update() calls that never
     look at the result can silently no-op under RLS (this shipped as a real
     bug: Check List delete "worked" while deleting nothing). The count of such
     call sites must never grow; shrink it over time by using the checked
     patterns. Baseline lives in scripts/unchecked_mutations.baseline.
  6. Cross-kitchen XSS guard — recipes from other kitchens (the Public shelf,
     db/131) render as innerHTML in every viewer's session, so foreign recipe
     text is a stored-XSS vector. The defence is a single data-boundary escaper
     (sanitizeForeignRecipe) called from dbRowToRecipe. This check fails if
     either the escaper or its call site disappears — so the fix can't be
     silently removed later. (Found in the 2026-07-17 security review.)

Why this exists (health check 2026-07-15): all five classes shipped to
production at least once, each caught only by a human noticing. This script is
what would have caught them first — run via .githooks/pre-commit and in CI.

Exit 0 = clean, 1 = violations.
"""
import re
import sys
import glob
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASELINE_FILE = os.path.join(REPO, 'scripts', 'unchecked_mutations.baseline')

SECRET_PATTERNS = [
    (re.compile(r'sk-ant-[a-zA-Z0-9_\-]{20,}'), 'Anthropic API key'),
    (re.compile(r're_[a-zA-Z0-9]{20,}'), 'Resend API key'),
    (re.compile(r'eyJ[a-zA-Z0-9_\-]{20,}\.eyJ[a-zA-Z0-9_\-]{20,}'), 'JWT (possible service_role key)'),
    (re.compile(r'sb_secret_[a-zA-Z0-9_\-]+'), 'Supabase secret key'),
]

def css_files():
    return sorted(glob.glob(os.path.join(REPO, 'app', '*.css')))

def html_files():
    files = [os.path.join(REPO, 'app', 'index.html')]
    files += sorted(glob.glob(os.path.join(REPO, 'app', '*.html')))
    files += sorted(glob.glob(os.path.join(REPO, 'visual data', '*.html')))
    seen, out = set(), []
    for f in files:
        if f not in seen and os.path.exists(f):
            seen.add(f); out.append(f)
    return out

def _tag_count_source(s):
    """Tag names quoted inside JS doc comments are prose, not markup. Strip block comments
    for TAG counting only — and only inside <script> blocks, and only comments that start
    at the beginning of a line: content like <code>db/*.sql</code> in the HTML body contains
    '/*' as a glob pattern, and treating that as a comment once ate 5 KB of real markup
    (found while building this very auditor)."""
    def clean_script(m):
        body = re.sub(r'^\s*/\*.*?\*/', '', m.group(2), flags=re.S | re.M)
        return m.group(1) + body + '</script>'
    return re.sub(r'(<script[^>]*>)(.*?)</script>', clean_script, s, flags=re.S)

def check_structure(path, s, violations):
    rel = os.path.relpath(path, REPO)
    tag_src = _tag_count_source(s)
    pairs = [('{', '}'), ('<div', '</div>'), ('<details', '</details>'), ('<section', '</section>')]
    for a, b in pairs:
        src = s if a == '{' else tag_src  # braces stay raw, matching the historical checks
        ca, cb = src.count(a), src.count(b)
        if ca != cb:
            violations.append(f'{rel}: unbalanced {a}...{b} ({ca} vs {cb})')
    ctrl = [c for c in s if ord(c) < 32 and c not in '\n\r\t']
    if ctrl:
        violations.append(f'{rel}: {len(ctrl)} stray control character(s) — bytes below 0x20')

def check_dead_buttons(path, s, violations):
    rel = os.path.relpath(path, REPO)
    if os.path.basename(path) != 'index.html' or '/app/' not in path.replace('\\', '/'):
        return  # only the app has a meaningful function namespace
    handlers = set(re.findall(r'onclick="\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\(', s))
    defined = set(re.findall(r'function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(', s))
    defined |= set(re.findall(r'(?:const|let|var|window\.)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(?:async\s*)?(?:function|\()', s))
    JS_BUILTINS = {'alert', 'confirm', 'prompt', 'if', 'event', 'window', 'location', 'this', 'void'}
    for h in sorted(handlers - defined - JS_BUILTINS):
        violations.append(f'{rel}: onclick references undefined function "{h}" — dead button')

def check_ghost_tables(s, violations):
    migrations = ' '.join(open(f, encoding='utf-8', errors='replace').read().lower()
                          for f in glob.glob(os.path.join(REPO, 'db', '*.sql')))
    for t in sorted(set(re.findall(r"sb\.from\('([a-z_]+)'\)", s))):
        if ('create table if not exists ' + t) in migrations or ('create table ' + t) in migrations \
           or ('alter table ' + t) in migrations:
            continue
        violations.append(f'app/index.html: sb.from(\'{t}\') but no db/*.sql migration creates or alters "{t}"')

def check_secrets(path, s, violations):
    rel = os.path.relpath(path, REPO)
    for pat, label in SECRET_PATTERNS:
        for m in pat.finditer(s):
            violations.append(f'{rel}: possible {label} committed: "{m.group(0)[:18]}…"')

def check_mutation_ratchet(s, violations):
    # A call site is "checked" when the statement's result is captured (const {...} = await ...)
    # or awaited into a variable; bare `await sb.from('x').delete()...;` / `.update(...)` with
    # nothing reading the result is the silent-no-op pattern.
    unchecked = len(re.findall(r'^\s*await\s+sb\.from\([^)]*\)\s*\.(?:delete|update)\(', s, re.M))
    try:
        baseline = int(open(BASELINE_FILE).read().strip())
    except (FileNotFoundError, ValueError):
        baseline = None
    if baseline is None:
        open(BASELINE_FILE, 'w').write(str(unchecked) + '\n')
        print(f'audit_app: wrote unchecked-mutation baseline = {unchecked}')
        return
    if unchecked > baseline:
        violations.append(
            f'app/index.html: unchecked Supabase delete/update call sites grew {baseline} → {unchecked}. '
            f'Capture the result and check error/affected rows (silent-no-op class). '
            f'If intentional, raise scripts/unchecked_mutations.baseline with justification in the commit message.')
    elif unchecked < baseline:
        open(BASELINE_FILE, 'w').write(str(unchecked) + '\n')
        print(f'audit_app: unchecked-mutation count improved {baseline} → {unchecked}, ratchet tightened.')

def check_recipe_xss_guard(s, violations):
    # The cross-kitchen XSS defences must stay wired: each escaper must exist AND its loader must
    # call it. Cheap substring checks that guard the guards, so nobody can quietly delete a
    # sanitizer and reopen a stored-XSS hole (2026-07-17).
    # Recipes (db/131 Public shelf).
    if 'function sanitizeForeignRecipe(' not in s:
        violations.append('app/index.html: sanitizeForeignRecipe() is gone — cross-kitchen recipe XSS defence removed (db/131 Public shelf renders foreign recipe text as innerHTML).')
    else:
        m = re.search(r'function dbRowToRecipe\(row\)\s*\{(.*?)\n\}', s, re.S)
        if 'sanitizeForeignRecipe(' not in (m.group(1) if m else ''):
            violations.append('app/index.html: dbRowToRecipe no longer calls sanitizeForeignRecipe() — foreign (Public-shelf) recipes would reach innerHTML unescaped (stored XSS).')
    # Ingredients (db/136 Public shelf + friend sharing).
    if 'function sanitizeForeignIngredient(' not in s:
        violations.append('app/index.html: sanitizeForeignIngredient() is gone — cross-kitchen ingredient XSS defence removed (db/136 renders foreign ingredient text as innerHTML).')
    elif 'sanitizeForeignIngredient(' not in re.sub(r'function sanitizeForeignIngredient\(ing\)\s*\{.*?\n\}', '', s, flags=re.S):
        violations.append('app/index.html: sanitizeForeignIngredient() is defined but never called — foreign (Public-shelf) ingredients would reach innerHTML unescaped (stored XSS).')

def main():
    violations = []
    app_index = os.path.join(REPO, 'app', 'index.html')
    for path in html_files():
        s = open(path, encoding='utf-8', errors='replace').read()
        check_structure(path, s, violations)
        check_secrets(path, s, violations)
    for path in css_files():
        css = open(path, encoding='utf-8', errors='replace').read()
        rel = os.path.relpath(path, REPO)
        if css.count('{') != css.count('}'):
            violations.append(f'{rel}: unbalanced CSS braces ({css.count("{")} vs {css.count("}")})')
        check_secrets(path, css, violations)
    s = open(app_index, encoding='utf-8', errors='replace').read()
    check_dead_buttons(app_index, s, violations)
    check_ghost_tables(s, violations)
    check_mutation_ratchet(s, violations)
    check_recipe_xss_guard(s, violations)

    if violations:
        print(f'audit_app: {len(violations)} violation(s):')
        for v in violations:
            print('  ✗ ' + v)
        return 1
    print('audit_app: clean — structure balanced, no dead buttons, no ghost tables, no secrets, ratchet holding.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
