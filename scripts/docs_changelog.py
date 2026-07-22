#!/usr/bin/env python3
"""Auto-generated changelog — "everything that happened", written into an Internal Doc from git.

Richard, 22.7.26: he ran the docs-QA robot and found the Internal Docs were NOT actually updated
with what we'd done — the QA robots only check RENDERING (nothing flies, EN/SK toggle, no
undefined/NaN), and the only freshness guard checked a DATE, not content. So nothing GUARANTEED
that what happened got written down. This closes that: the changelog is generated straight from
git commit subjects (which we always write in detail), grouped by Bern day — so it can never miss
anything a human forgot to type. Runs in the pre-commit hook (always current) and is guarded in CI.

Commands:
  python3 scripts/docs_changelog.py            # (re)generate visual data/changelog.html from git
  python3 scripts/docs_changelog.py --check     # CI guard: fail if any commit (except HEAD) is
                                                #   missing from the committed changelog

The pre-commit lag: at commit time the in-flight commit doesn't exist yet, so the changelog it
writes covers everything UP TO its parent; the new commit's own line lands on the next commit.
--check therefore allows exactly the HEAD commit to be absent, and requires every older commit's
short hash to be present — so a bypassed hook (or a hand-edited changelog) is caught.
"""
import html
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, 'visual data', 'changelog.html')
BERN = 'Europe/Zurich'

# Auto-build/bookkeeping commits still count as "what happened", but their subjects are noise in a
# human changelog. Keep them (completeness) but tag them muted so the eye skips them.
MUTED_PREFIXES = ('Session close:', 'Recipes lock: first run', 'Promote recipes')


def git_log():
    """[(short_hash, 'YYYY-MM-DD' (Bern), subject)] newest-first. Excludes merge commits."""
    env = dict(os.environ, TZ=BERN)
    out = subprocess.check_output(
        ['git', '-C', REPO, 'log', '--no-merges',
         '--date=format-local:%Y-%m-%d', '--pretty=format:%h\x1f%ad\x1f%s'],
        env=env, text=True)
    rows = []
    for line in out.splitlines():
        parts = line.split('\x1f')
        if len(parts) == 3:
            rows.append((parts[0], parts[1], parts[2]))
    return rows


def head_hash():
    return subprocess.check_output(['git', '-C', REPO, 'rev-parse', '--short', 'HEAD'], text=True).strip()


SK_DAY = {'Mon': 'Po', 'Tue': 'Ut', 'Wed': 'St', 'Thu': 'Št', 'Fri': 'Pi', 'Sat': 'So', 'Sun': 'Ne'}


def build_html(rows):
    # group by day, preserving newest-first order
    days = []
    seen = {}
    for h, d, s in rows:
        if d not in seen:
            seen[d] = []
            days.append(d)
        seen[d].append((h, s))

    day_blocks = []
    for d in days:
        items = seen[d]
        lines = []
        for h, s in items:
            muted = ' muted' if s.startswith(MUTED_PREFIXES) else ''
            lines.append(
                f'<li class="cl-item{muted}"><code class="cl-hash">{html.escape(h)}</code>'
                f'<span class="cl-msg">{html.escape(s)}</span></li>')
        day_blocks.append(
            f'<section class="cl-day"><h2 class="cl-date">{html.escape(d)}'
            f'<span class="cl-count">{len(items)} {"zmien" if len(items) != 1 else "zmena"} · '
            f'{len(items)} change{"s" if len(items) != 1 else ""}</span></h2>'
            f'<ul class="cl-list">{"".join(lines)}</ul></section>')

    total = len(rows)
    body = "\n".join(day_blocks) if day_blocks else '<p class="cl-empty">Zatiaľ žiadne commity. · No commits yet.</p>'
    # Self-contained, navy/teal, responsive. The frame carries data-sk/data-en so the EN/SK toggle
    # the other docs use works here too; commit lines are plain (raw record, not translated) so the
    # QA robot's "one-sided bilingual element" check never trips on them.
    return f"""<!doctype html>
<html lang="sk">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Changelog — Sautero</title>
<style>
  :root{{ --bg:#0A1A2F; --ink:#EAF2F5; --ink-dim:#9DB2BD; --accent:#34F7D7; --copper:#34F7D7;
         --rule:rgba(52,247,215,.18); --raised:#0E2237; }}
  *{{ box-sizing:border-box; }}
  body{{ margin:0; background:var(--bg); color:var(--ink); font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
         padding:0 0 80px; line-height:1.5; -webkit-text-size-adjust:100%; }}
  .cl-topbar{{ position:sticky; top:0; z-index:5; display:flex; align-items:center; justify-content:space-between;
              gap:10px; padding:10px 18px; background:rgba(10,26,47,.92); backdrop-filter:blur(6px);
              border-bottom:1px solid var(--rule); }}
  .cl-topbar .cl-brand{{ font-family:Georgia,serif; font-style:italic; font-size:16px; }}
  .cl-lang{{ font-family:inherit; font-size:12px; font-weight:700; color:var(--ink); background:transparent;
            border:1px solid var(--copper); border-radius:999px; padding:5px 12px; cursor:pointer; }}
  .cl-lang:active{{ transform:scale(.95); }}
  .cl-wrap{{ max-width:760px; margin:0 auto; padding:22px 18px 0; }}
  .cl-kicker{{ font-size:11px; letter-spacing:.18em; text-transform:uppercase; color:var(--accent); font-weight:700; margin:0 0 4px; }}
  h1.cl-title{{ font-family:Georgia,'Times New Roman',serif; font-style:italic; font-size:30px; margin:0 0 6px; }}
  .cl-lede{{ color:var(--ink-dim); font-size:14px; margin:0 0 6px; max-width:60ch; }}
  .cl-meta{{ color:var(--ink-dim); font-size:12px; margin:0 0 22px; }}
  .cl-day{{ margin:0 0 22px; }}
  h2.cl-date{{ display:flex; flex-wrap:wrap; align-items:baseline; gap:10px; font-size:18px; margin:0 0 10px;
              padding-bottom:6px; border-bottom:1px solid var(--rule); }}
  .cl-count{{ font-size:11px; color:var(--ink-dim); font-weight:400; }}
  ul.cl-list{{ list-style:none; margin:0; padding:0; }}
  li.cl-item{{ display:flex; gap:10px; align-items:flex-start; padding:7px 0; border-bottom:1px solid rgba(255,255,255,.04); }}
  li.cl-item.muted{{ opacity:.55; }}
  .cl-hash{{ flex:0 0 auto; font-family:ui-monospace,SFMono-Regular,Menlo,monospace; font-size:11.5px;
            color:#0A1A2F; background:var(--accent); border-radius:5px; padding:2px 7px; margin-top:1px; }}
  .cl-msg{{ flex:1 1 auto; min-width:0; font-size:14px; overflow-wrap:anywhere; word-break:break-word; }}
  .cl-empty{{ color:var(--ink-dim); }}
</style>
</head>
<body>
<div class="cl-topbar">
  <span class="cl-brand">Sautero</span>
  <button class="cl-lang" onclick="toggleLang()" title="EN / SK">EN/SK</button>
</div>
<div class="cl-wrap">
  <p class="cl-kicker" data-sk="Interný záznam" data-en="Internal record">Interný záznam</p>
  <h1 class="cl-title" data-sk="Changelog" data-en="Changelog">Changelog</h1>
  <p class="cl-lede" data-sk="Kompletný záznam každej zmeny, generovaný automaticky z git commitov (bernský čas). Nič sa nezabudne — zdrojom sú samotné commity."
                     data-en="A complete record of every change, generated automatically from git commits (Bern time). Nothing gets forgotten — the commits themselves are the source.">Kompletný záznam každej zmeny, generovaný automaticky z git commitov (bernský čas). Nič sa nezabudne — zdrojom sú samotné commity.</p>
  <p class="cl-meta"><span data-sk="Spolu {total} zmien · generované automaticky" data-en="{total} changes total · generated automatically">Spolu {total} zmien · generované automaticky</span></p>
  {body}
</div>
<script>
  // EN/SK toggle for the frame text (commit lines stay in their raw English — they're the record).
  var _clLang = 'sk';
  function toggleLang(){{
    _clLang = _clLang === 'sk' ? 'en' : 'sk';
    document.querySelectorAll('[data-sk][data-en]').forEach(function(el){{
      var v = el.getAttribute('data-' + _clLang);
      if(v != null) el.textContent = v;
    }});
    document.documentElement.lang = _clLang;
  }}
</script>
</body>
</html>
"""


def cmd_generate():
    rows = git_log()
    with open(OUT, 'w', encoding='utf-8') as fh:
        fh.write(build_html(rows))
    print(f'docs_changelog: wrote changelog.html ({len(rows)} commits across '
          f'{len({r[1] for r in rows})} day(s)).')
    return 0


def cmd_check():
    if not os.path.exists(OUT):
        print('docs_changelog: changelog.html is MISSING — run docs_changelog.py to generate it.')
        return 1
    with open(OUT, encoding='utf-8') as fh:
        content = fh.read()
    rows = git_log()
    head = head_hash()
    # every commit EXCEPT the in-flight HEAD must already be recorded (by short hash)
    missing = [h for (h, _d, _s) in rows if h != head and f'>{h}<' not in content]
    if missing:
        print(f'docs_changelog: changelog.html is BEHIND git — {len(missing)} commit(s) not '
              f'recorded: {", ".join(missing[:8])}{" …" if len(missing) > 8 else ""}. '
              f'Regenerate it (python3 scripts/docs_changelog.py) — the pre-commit hook does this '
              f'automatically, so a miss means the hook was bypassed or the file was hand-edited.')
        return 1
    print(f'docs_changelog: current — all {len(rows) - 1} past commit(s) recorded (HEAD {head} lands next commit).')
    return 0


def main():
    if '--check' in sys.argv:
        return cmd_check()
    return cmd_generate()


if __name__ == '__main__':
    sys.exit(main())
