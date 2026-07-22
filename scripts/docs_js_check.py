#!/usr/bin/env python3
"""JS syntax guard for the Internal Docs' inline scripts (Richard, 22.7.26 — after a bad string
escape in poznamky_src.html silently blanked the whole notebook: 'poznámky nefungujú').

Those docs render a data array (NOTES / MODULES / DAYS …) from an inline <script>. A single broken
string literal there throws on load and the page renders EMPTY — and nothing on-push caught it (the
docs-QA render robot runs 2×/day, not on every commit). This closes that: it extracts every INLINE
<script> from the source docs and runs `node --check` (V8's own parser) on each, so a syntax error
fails the build before it can ship. Pure syntax — the browser globals the scripts use aren't
executed, so `document`, `localStorage`, etc. are irrelevant here.

Needs node (CI has it for calc_unit_test.js; skipped locally with a note, same as that test).

  python3 scripts/docs_js_check.py            # exit 1 if any inline doc script has a syntax error
"""
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VDIR = os.path.join(REPO, 'visual data')

# inline <script> ... </script> only — skip <script src="..."> (external, nothing to parse here)
SCRIPT_RE = re.compile(r'<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>', re.S | re.I)


def inline_scripts(path):
    with open(path, encoding='utf-8') as fh:
        html = fh.read()
    return [m.group(1) for m in SCRIPT_RE.finditer(html) if m.group(1).strip()]


def main():
    if not shutil.which('node'):
        print('docs_js_check: node not found — skipping locally (CI runs it, same as calc_unit_test.js).')
        return 0

    docs = sorted(glob.glob(os.path.join(VDIR, '*.html')))
    failures = []
    checked = 0
    with tempfile.TemporaryDirectory() as tmp:
        for path in docs:
            for idx, code in enumerate(inline_scripts(path)):
                checked += 1
                js = os.path.join(tmp, f'chunk_{idx}.js')
                with open(js, 'w', encoding='utf-8') as fh:
                    fh.write(code)
                res = subprocess.run(['node', '--check', js], capture_output=True, text=True)
                if res.returncode != 0:
                    # node prints "file:line" + a caret; keep the first meaningful lines
                    msg = (res.stderr.strip().splitlines() or ['syntax error'])
                    detail = ' / '.join(line.strip() for line in msg[:4] if line.strip())
                    failures.append((os.path.basename(path), idx, detail))

    if failures:
        print(f'docs_js_check: {len(failures)} inline doc script(s) have a SYNTAX ERROR '
              f'(the class that blanked Poznámky):')
        for name, idx, detail in failures:
            print(f'  ✗ {name} (script #{idx + 1}): {detail}')
        return 1
    print(f'docs_js_check: clean — {checked} inline doc script(s) parse.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
