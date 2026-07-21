# -*- coding: utf-8 -*-
"""Renderer for the Sautero Health Report dashboard (visual data/health.html).

Given the report dict from health_report.py, returns a self-contained navy/teal HTML page:
score rings, four tap-to-expand audit sections, bilingual SK/EN toggle (shared
localStorage key sautero_doc_lang), theme-locked to the Sautero identity. No external
resources (CSP-safe). Auto-generated — do not hand-edit visual data/health.html.

Bilingual policy: all prose (headings, section blurbs, status words, check descriptions) is
SK+EN. Technical metric NAMES that are code identifiers or standard terms (RLS, innerHTML,
sb.from(), TODO/FIXME) stay as shared technical terms. Any check name missing from SK_CHECK
falls back to English, so adding a check in health_report.py never breaks the render.
"""
import html

# SK translations for the fixed set of section + check names produced by health_report.py.
SK_SECTION = {
    'Architecture': 'Architektúra', 'Security': 'Bezpečnosť',
    'Documentation': 'Dokumentácia', 'Technical Debt': 'Technický dlh',
}
SK_CHECK = {
    'Single-file app size': 'Veľkosť single-file appky',
    'Functions defined': 'Definované funkcie',
    'Duplicate function names': 'Duplicitné názvy funkcií',
    'Dead functions (defined, never referenced)': 'Mŕtve funkcie (definované, nepoužité)',
    'Functions > 150 lines': 'Funkcie nad 150 riadkov',
    'DB tables created': 'Vytvorené DB tabuľky',
    'Orphan tables (created, app never queries)': 'Osirelé tabuľky (appka ich nikdy nečíta)',
    'Ghost tables (queried, never created)': 'Duchové tabuľky (čítané, nikdy nevytvorené)',
    'audit_app gate (structure, secrets, XSS guard, ratchet)': 'audit_app brána (štruktúra, tajomstvá, XSS, ratchet)',
    'audit_db gate (RLS, tenant scoping, destructive SQL)': 'audit_db brána (RLS, tenant scoping, deštruktívne SQL)',
    'Off-site scripts/styles loaded': 'Načítané cudzie skripty/štýly',
    'Cross-kitchen XSS escapers wired': 'XSS escapery medzi kuchyňami zapojené',
    'innerHTML sinks': 'innerHTML miesta',
    'Explicit kitchen_id filters in app reads': 'Explicitné kitchen_id filtre v čítaniach',
    'Tables with RLS enabled': 'Tabuľky so zapnutým RLS',
    'Secrets in edge functions': 'Tajomstvá v edge funkciách',
    'Leftover "ChefOS" brand in docs': 'Zvyšky značky „ChefOS" v dokumentoch',
    'Bilingual docs complete (SK/EN)': 'Dvojjazyčné dokumenty kompletné (SK/EN)',
    'build_docs sources missing': 'Chýbajúce zdroje build_docs',
    'Dashboards in visual data/': 'Dashboardy v visual data/',
    'Docs carrying a date stamp': 'Dokumenty s dátumovou pečiatkou',
    'TODO / FIXME / HACK / XXX markers': 'TODO / FIXME / HACK / XXX značky',
    'Stray console.log': 'Zabudnuté console.log',
    'Stray debugger statements': 'Zabudnuté debugger príkazy',
    'Unchecked mutation ratchet': 'Ratchet neoverených mutácií',
    'Dead functions': 'Mŕtve funkcie',
    'DB-contract rebrand debt (guarded)': 'Dlh DB-kontraktu z rebrandu (strážený)',
}
SK_STATUS = {'ok': 'v poriadku', 'warn': 'pozor', 'fail': 'zlyhanie'}
SK_BLURB = {
    'Architecture': 'Štruktúra kódu: veľkosť, funkcie, tabuľky, väzby.',
    'Security': 'Obrany appky: RLS, XSS hranice, tajomstvá, cudzie zdroje.',
    'Documentation': 'Zdravie dokumentov: značka, dvojjazyčnosť, aktuálnosť.',
    'Technical Debt': 'Nahromadený dlh: značky, mŕtvy kód, ratchet.',
}
EN_BLURB = {
    'Architecture': 'Code structure: size, functions, tables, coupling.',
    'Security': 'App defences: RLS, XSS boundaries, secrets, off-site resources.',
    'Documentation': 'Docs health: brand, bilingual completeness, freshness.',
    'Technical Debt': 'Accumulated debt: markers, dead code, ratchet.',
}


def _t(en, sk):
    """A bilingual span: shows EN or SK per the active toggle."""
    return f'<span data-en="{html.escape(en)}" data-sk="{html.escape(sk)}">{html.escape(en)}</span>'


def _ring(score, size=132, stroke=11):
    import math
    r = (size - stroke) / 2
    c = 2 * math.pi * r
    off = c * (1 - score / 100)
    col = '#34F7D7' if score >= 80 else '#F7C948' if score >= 60 else '#FF5C7A'
    cx = size / 2
    num_fs = round(size * 0.26)   # scales with ring size so 3-digit "100" never overflows
    sub_fs = round(size * 0.095)
    return f'''<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" class="ring">
      <circle cx="{cx}" cy="{cx}" r="{r}" stroke="rgba(255,255,255,.08)" stroke-width="{stroke}" fill="none"/>
      <circle cx="{cx}" cy="{cx}" r="{r}" stroke="{col}" stroke-width="{stroke}" fill="none"
        stroke-linecap="round" stroke-dasharray="{c:.1f}" stroke-dashoffset="{off:.1f}"
        transform="rotate(-90 {cx} {cx})"/>
      <text x="50%" y="48%" text-anchor="middle" dominant-baseline="middle" fill="{col}"
        style="font-size:{num_fs}px;font-weight:800;">{score}</text>
      <text x="50%" y="70%" text-anchor="middle" dominant-baseline="middle" fill="#8FA9BF"
        style="font-size:{sub_fs}px;">/ 100</text>
    </svg>'''


def render(report):
    blocks = report['blocks']
    pill = {'ok': 'st-ok', 'warn': 'st-warn', 'fail': 'st-fail'}

    sections = []
    for b in blocks:
        rows = []
        for c in b['checks']:
            nm = c['name']
            label = f'<span data-en="{html.escape(nm)}" data-sk="{html.escape(SK_CHECK.get(nm, nm))}">{html.escape(nm)}</span>'
            sw = c['status']
            stword = f'<span data-en="{SK_STATUS[sw] and sw}" data-sk="{SK_STATUS[sw]}">{sw}</span>'
            rows.append(f'''<div class="row">
                <span class="pill {pill[sw]}">{stword}</span>
                <div class="rc"><div class="rn">{label}</div>
                  <div class="rd" data-en="{html.escape(c['detail'])}" data-sk="{html.escape(c['detail'])}">{html.escape(c['detail'])}</div></div>
                <span class="rv">{html.escape(str(c['value']))}</span>
              </div>''')
        gcol = '#34F7D7' if b['score'] >= 80 else '#F7C948' if b['score'] >= 60 else '#FF5C7A'
        sections.append(f'''<details class="audit">
          <summary>
            <div class="au-head">
              <div class="au-ring">{_ring(b['score'], 74, 7)}</div>
              <div class="au-meta">
                <h3>{_t(b['name'], SK_SECTION.get(b['name'], b['name']))}</h3>
                <p class="au-blurb">{_t(EN_BLURB.get(b['name'],''), SK_BLURB.get(b['name'],''))}</p>
              </div>
              <div class="au-grade" style="color:{gcol}">{b['grade']}</div>
              <div class="au-caret">▾</div>
            </div>
          </summary>
          <div class="rows">{''.join(rows)}</div>
        </details>''')

    overall_col = '#34F7D7' if report['overall_score'] >= 80 else '#F7C948' if report['overall_score'] >= 60 else '#FF5C7A'
    return f'''<!doctype html>
<html lang="en"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sautero · Health Report</title>
<style>
  :root{{--navy:#0A1A2F;--navy2:#06111F;--card:#0E2338;--teal:#34F7D7;--ink:#E8F1F8;--mut:#8FA9BF;--line:rgba(255,255,255,.08);}}
  *{{box-sizing:border-box;min-width:0;}}
  html,body{{margin:0;padding:0;max-width:100%;overflow-x:hidden;}}
  body{{background:radial-gradient(1200px 600px at 50% -10%,#12293f 0%,var(--navy) 45%,var(--navy2) 100%);
    color:var(--ink);font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
    -webkit-font-smoothing:antialiased;line-height:1.5;font-variant-numeric:tabular-nums;}}
  .wrap{{max-width:820px;margin:0 auto;padding:28px 20px 60px;}}
  .topbar{{display:flex;justify-content:space-between;align-items:center;gap:12px;
    position:sticky;top:0;z-index:20;padding:14px 0;margin-bottom:12px;
    background:linear-gradient(180deg,var(--navy) 70%,rgba(10,26,47,0));}}
  .brand{{display:flex;align-items:center;gap:10px;font-weight:700;letter-spacing:.02em;}}
  .brand .dot{{width:11px;height:11px;border-radius:50%;background:var(--teal);box-shadow:0 0 14px var(--teal);}}
  .brand small{{color:var(--mut);font-weight:500;letter-spacing:.14em;text-transform:uppercase;font-size:11px;}}
  .langtog{{border:1px solid var(--line);background:rgba(255,255,255,.03);color:var(--ink);
    border-radius:999px;padding:7px 14px;font-size:13px;font-weight:600;cursor:pointer;}}
  .langtog .on{{color:var(--teal);}}
  .langtog .off{{color:var(--mut);}}
  .hero{{background:linear-gradient(180deg,rgba(52,247,215,.06),rgba(255,255,255,0));border:1px solid var(--line);
    border-radius:22px;padding:26px;display:flex;align-items:center;gap:26px;margin-bottom:14px;}}
  .hero .htext h1{{margin:0 0 4px;font-size:26px;letter-spacing:-.01em;text-wrap:balance;}}
  .hero .htext p{{margin:0;color:var(--mut);font-size:14px;}}
  .hero .grade-big{{margin-left:auto;font-size:56px;font-weight:800;line-height:1;color:{overall_col};}}
  .ring .ring-num{{font-size:34px;font-weight:800;}}
  .ring .ring-sub{{font-size:12px;fill:var(--mut);}}
  .stamp{{color:var(--mut);font-size:12.5px;margin:2px 0 22px;letter-spacing:.02em;}}
  .audit{{background:var(--card);border:1px solid var(--line);border-radius:18px;margin-bottom:13px;overflow:hidden;}}
  .audit>summary{{list-style:none;cursor:pointer;padding:16px 18px;}}
  .audit>summary::-webkit-details-marker{{display:none;}}
  .au-head{{display:flex;align-items:center;gap:16px;}}
  .au-ring{{flex:none;}}
  .au-meta{{flex:1;}}
  .au-meta h3{{margin:0;font-size:18px;letter-spacing:-.01em;}}
  .au-blurb{{margin:2px 0 0;color:var(--mut);font-size:13px;}}
  .au-grade{{font-size:30px;font-weight:800;line-height:1;}}
  .au-caret{{color:var(--mut);transition:transform .2s;font-size:14px;}}
  .audit[open] .au-caret{{transform:rotate(180deg);}}
  .rows{{border-top:1px solid var(--line);padding:6px 18px 16px;}}
  .row{{display:flex;align-items:flex-start;gap:12px;padding:12px 0;border-bottom:1px solid rgba(255,255,255,.05);}}
  .row:last-child{{border-bottom:none;}}
  .rc{{flex:1;}}
  .rn{{font-size:14.5px;font-weight:600;}}
  .rd{{color:var(--mut);font-size:12.8px;margin-top:2px;}}
  .rv{{flex:none;font-weight:700;font-size:14px;color:var(--ink);white-space:nowrap;}}
  .pill{{flex:none;font-size:10.5px;font-weight:800;letter-spacing:.08em;text-transform:uppercase;
    padding:4px 9px;border-radius:999px;margin-top:1px;}}
  .st-ok{{background:rgba(52,247,215,.14);color:var(--teal);}}
  .st-warn{{background:rgba(247,201,72,.16);color:#F7C948;}}
  .st-fail{{background:rgba(255,92,122,.16);color:#FF5C7A;}}
  .foot{{color:var(--mut);font-size:12px;margin-top:24px;text-align:center;line-height:1.7;}}
  .foot code{{color:var(--teal);background:rgba(255,255,255,.04);padding:1px 6px;border-radius:6px;}}
  .datestamp{{position:fixed;right:9px;bottom:8px;z-index:60;font-size:10.5px;font-weight:600;color:var(--mut);background:rgba(6,17,31,.85);border:1px solid var(--line);border-radius:8px;padding:3px 9px;pointer-events:none;}}
</style></head>
<body><div class="wrap">
  <div class="topbar">
    <div class="brand"><span class="dot"></span>SAUTERO&nbsp;<small>Health Report</small></div>
    <button class="langtog" onclick="toggleLang()"><span id="lcEn">EN</span> / <span id="lcSk">SK</span></button>
  </div>

  <div class="hero">
    <div class="hring">{_ring(report['overall_score'])}</div>
    <div class="htext">
      <h1>{_t('Codebase Health', 'Zdravie kódovej bázy')}</h1>
      <p>{_t('Four automated audits over the real repository.', 'Štyri automatické audity nad reálnym repozitárom.')}</p>
    </div>
    <div class="grade-big">{report['overall_grade']}</div>
  </div>
  <div class="stamp">{_t('Generated', 'Vygenerované')}: {html.escape(report['generated'])} · {_t('auto-generated 2×/day, never hand-edited', 'auto-generované 2×/deň, ručne needitované')}</div>

  {''.join(sections)}

  <div class="foot">
    {_t('Static analysis only — it grades, it does not block the build.', 'Iba statická analýza — hodnotí, nezastavuje build.')}<br>
    {_t('Build-blocking checks live in', 'Build blokujúce kontroly sú v')} <code>audit_app.py</code> · <code>audit_db.py</code> · <code>calc_unit_test.js</code>.
  </div>
</div>
<div class="datestamp" data-sk="Aktualizované {html.escape(report['generated'].split()[0])}" data-en="Updated {html.escape(report['generated'].split()[0])}">Aktualizované {html.escape(report['generated'].split()[0])}</div>
<script>
  var KEY='sautero_doc_lang';
  function applyLang(l){{
    document.querySelectorAll('[data-en]').forEach(function(el){{
      var v=el.getAttribute('data-'+l); if(v!=null) el.textContent=v;
    }});
    var en=document.getElementById('lcEn'), sk=document.getElementById('lcSk');
    if(en&&sk){{ en.className=(l==='en'?'on':'off'); sk.className=(l==='sk'?'on':'off'); }}
    document.documentElement.lang=l;
  }}
  function toggleLang(){{
    var cur=localStorage.getItem(KEY)==='sk'?'sk':'en';
    var nxt=cur==='sk'?'en':'sk'; localStorage.setItem(KEY,nxt); applyLang(nxt);
  }}
  applyLang(localStorage.getItem(KEY)==='sk'?'sk':'en');
</script>
</body></html>'''
