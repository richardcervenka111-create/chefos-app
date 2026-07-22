#!/usr/bin/env python3
"""UI/UX invariants — static guards for the classes of UI bug we've actually hit (Richard, 22.7.).

These are SOURCE-level checks: fast, need no browser and no secrets, so they run on every push
(health-checks + the deploy gate). Each guard pins a specific past bug so it can't come back:

  1. Status pill (#bgScanPill) — the trailing status emoji must sit INSIDE the rounded cap.
     Bug (22.7.): right padding (16px) was smaller than the semicircular right cap radius, so a
     tall colour emoji spilled out of the bubble. Guard: right padding >= effective right radius.

  2. "Save where?" sheet (#scanSaveDestOverlay) — a sub-sheet opened FROM the menu-scan review
     must stack ABOVE it. Bug (22.7.): equal z-index + earlier DOM position => it opened BEHIND
     the review, invisible until the list was closed. Guard: its z-index > the base .sheet-overlay.

  3. AI photo cost logging — every successful image return in generate-image must be preceded by
     logImageUsage(), or Admin -> AI Usage silently misses this feature's cost. Guard: each
     `return json(200, { imageBase64 ... }` has a logImageUsage() call just above it.

  4. Scroll-to-top uses the REAL scroller — the live scroll container is <body>, not window, so
     window.scrollTo is a no-op (verified live 22.7.). Bug: recipes opened mid-page. Guard:
     _appScrollTo() is defined and showDetail() uses it (never a bare window.scrollTo as its reset).

Run: python3 scripts/ui_invariants.py    (exit 1 on any failure)
Adding a new UI guard here when we fix a UI bug is part of the Engineering Standard (never let a
fixed UI bug regress silently).
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, 'app', 'index.html')
GEN_IMAGE = os.path.join(ROOT, 'supabase', 'functions', 'generate-image', 'index.ts')

# A pill is a short bar; its rounded cap can't curve in by more than ~half its height. If the
# right padding clears this, a right-aligned glyph is always drawn in the flat zone.
PILL_MAX_CAP_PX = 18

failures = []
passes = []


def read(path):
    with open(path, encoding='utf-8') as fh:
        return fh.read()


def find_element_style(html, element_id):
    """Return the inline style="..." string of the element with the given id, or None."""
    # match id="x" ... style="..."  OR  style="..." ... id="x" on the same tag
    m = re.search(r'id="' + re.escape(element_id) + r'"[^>]*?\sstyle="([^"]*)"', html)
    if not m:
        m = re.search(r'style="([^"]*)"[^>]*?\sid="' + re.escape(element_id) + r'"', html)
    return m.group(1) if m else None


def css_prop(style, name):
    m = re.search(r'(?:^|;)\s*' + re.escape(name) + r'\s*:\s*([^;]+)', style)
    return m.group(1).strip() if m else None


def px_list(value):
    """['9px','24px',...] -> [9.0, 24.0, ...] (non-px tokens like 'calc(...)' -> None)."""
    out = []
    for tok in value.split():
        m = re.match(r'^(-?\d+(?:\.\d+)?)px$', tok.strip())
        out.append(float(m.group(1)) if m else None)
    return out


# ---------------------------------------------------------------- 1. status pill containment
def check_status_pill(html):
    style = find_element_style(html, 'bgScanPill')
    if not style:
        failures.append('pill: could not find #bgScanPill inline style.')
        return
    padding = css_prop(style, 'padding')
    radius = css_prop(style, 'border-radius')
    if not padding or not radius:
        failures.append('pill: #bgScanPill is missing padding or border-radius.')
        return
    # padding: T R B L (or T RL, or all) -> right value
    pad = px_list(padding)
    if len(pad) == 4:
        pad_right = pad[1]
    elif len(pad) == 2:
        pad_right = pad[1]
    elif len(pad) == 1:
        pad_right = pad[0]
    else:
        pad_right = pad[1] if len(pad) > 1 else None
    if pad_right is None:
        failures.append(f'pill: could not read a px right-padding from "{padding}".')
        return
    # border-radius: TL TR BR BL (999px = full cap). Right corners = TR, BR.
    rad = css_prop(style, 'border-radius').split()
    def rad_px(tok):
        m = re.match(r'^(\d+(?:\.\d+)?)px$', tok)
        return float(m.group(1)) if m else 0.0
    if len(rad) >= 3:
        tr, br = rad_px(rad[1]), rad_px(rad[2])
    else:
        tr = br = rad_px(rad[0]) if rad else 0.0
    cap = min(max(tr, br), PILL_MAX_CAP_PX)   # a huge radius is clamped to the physical half-height
    if pad_right + 0.01 < cap:
        failures.append(
            f'pill: #bgScanPill right padding {pad_right}px < effective right cap {cap}px — a '
            f'right-aligned status emoji will spill out of the rounded bubble (the 22.7. bug). '
            f'Increase right padding or reduce the right border-radius.')
    else:
        passes.append(f'pill: status emoji stays inside the cap (right padding {pad_right}px >= cap {cap}px).')


# ---------------------------------------------------------- 2. save-dest sheet stacks on top
def check_save_dest_zindex(html):
    # base .sheet-overlay z-index
    m = re.search(r'\.sheet-overlay\s*\{[^}]*?z-index:\s*(\d+)', html)
    if not m:
        failures.append('sheet: could not find base .sheet-overlay z-index.')
        return
    base_z = int(m.group(1))
    style = find_element_style(html, 'scanSaveDestOverlay')
    if not style:
        failures.append('sheet: could not find #scanSaveDestOverlay inline style.')
        return
    z = css_prop(style, 'z-index')
    if z is None or not z.strip().isdigit():
        failures.append('sheet: #scanSaveDestOverlay has no explicit numeric z-index — it will '
                        'open BEHIND the menu-scan review (equal z + later DOM). The 22.7. bug.')
        return
    if int(z) <= base_z:
        failures.append(f'sheet: #scanSaveDestOverlay z-index {z} <= base .sheet-overlay {base_z} — '
                        f'the "Save where?" sheet must stack ABOVE the review list.')
    else:
        passes.append(f'sheet: "Save where?" stacks above the review (z {z} > base {base_z}).')


# ------------------------------------------------------------- 3. AI photo cost logging present
def check_image_cost_logging(ts):
    lines = ts.splitlines()
    ok = True
    seen = 0
    for i, line in enumerate(lines):
        if 'return json(200' in line and 'imageBase64' in line:
            seen += 1
            # look at the up-to-3 preceding non-blank lines for the logging call
            window = '\n'.join(lines[max(0, i - 3):i])
            if 'logImageUsage(' not in window:
                ok = False
                failures.append(f'cost: generate-image line {i+1} returns an image without a '
                                f'preceding logImageUsage() — Admin AI Usage would miss its cost.')
    if seen == 0:
        failures.append('cost: no `return json(200, { imageBase64 ... }` found in generate-image — '
                        'did the success shape change? Update this guard.')
    elif ok:
        passes.append(f'cost: all {seen} image successes log their cost before returning.')


# --------------------------------------------------------- 4. scroll-to-top uses real scroller
def check_scroll_helper(html):
    if '_appScrollTo' not in html or 'function _appScrollTo' not in html:
        failures.append('scroll: _appScrollTo() helper is missing — full-page views must reset the '
                        'real body scroller, not window (window.scrollTo is a no-op here).')
        return
    m = re.search(r'function showDetail\(idx\)\{(.*?)\n\}\n', html, re.S)
    body = m.group(1) if m else ''
    if not m:
        # fall back to a generous slice
        idx = html.find('function showDetail(idx){')
        body = html[idx:idx + 4000] if idx >= 0 else ''
    if '_appScrollTo(0)' not in body:
        failures.append('scroll: showDetail() no longer resets via _appScrollTo(0) — a recipe will '
                        'open at the previous scroll position instead of its top (the 22.7. bug).')
    else:
        passes.append('scroll: showDetail() resets the real scroller via _appScrollTo(0).')


# ------------------------------------------- 5. personal/company toggle present + centered
def check_mode_toggle(html):
    # Richard, 22.7.: the personal/company toggle must live centered in the top bar on EVERY
    # screen. Guard both instances (Home badge + floating-nav) and that each sits in a centering
    # .mode-toggle-zone, so a refactor can't quietly drop it or knock it off-centre.
    ok = True
    for tid in ('homeAccountTypeBadge', 'navAccountTypeToggle'):
        if f'id="{tid}"' not in html:
            ok = False
            failures.append(f'toggle: #{tid} is missing — the personal/company toggle must show '
                            f'centered in the top bar on every screen.')
    zones = html.count('class="mode-toggle-zone"')
    if zones < 2:
        ok = False
        failures.append(f'toggle: expected 2 .mode-toggle-zone wrappers (Home + floating-nav), '
                        f'found {zones} — the toggle centering wrapper was dropped.')
    if ok:
        passes.append('toggle: personal/company toggle present + centered in both top bars.')


def main():
    html = read(APP)
    check_status_pill(html)
    check_save_dest_zindex(html)
    check_scroll_helper(html)
    check_mode_toggle(html)
    if os.path.exists(GEN_IMAGE):
        check_image_cost_logging(read(GEN_IMAGE))
    else:
        failures.append('cost: generate-image/index.ts not found.')

    for p in passes:
        print('  ok  ' + p)
    if failures:
        print()
        for f in failures:
            print('  FAIL ' + f)
        print(f'\nui_invariants: {len(failures)} UI guard(s) FAILED.')
        return 1
    print(f'\nui_invariants: clean — {len(passes)} UI guard(s) holding.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
