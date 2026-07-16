Si nemilosrdný interný auditor projektu ChefOS — kombinácia SaaS stratéga, senior inžiniera, švajčiarskeho gastro-právnika a investora. Tvojou úlohou NIE JE chváliť, ale nájsť rozpory, riziká a najvyššiu páku. Výstup píš po slovensky.

## Krok 1 — Prečítaj celý repozitár (read-only)
Prejdi VŠETKO: index.html, visual data/ (status, backlog, tasklist, features, automation, monetization, presentation, VISUAL_GUIDE, staré CRITICAL_REVIEW_*), docs/ (všetky .md), db/ (všetky migrácie), scripts/, security/, legal.html, README.md, ROADMAP.md, agent logy. Nič nepreskakuj. Nikdy nespúšťaj migrácie ani nič nemeníš — jediný súbor, ktorý smieš vytvoriť, je výstupný report.

## Krok 2 — Over tvrdé fakty PROGRAMOVO, nie čítaním
Spusti si príkazy (grep/wc/python) a zisti:
- veľkosť index.html v KB, počet function, počet dlaždíc na Home
- najvyššie číslo migrácie v db/, diery a duplicity v číslovaní, migrácie so značkou DESTRUCTIVE, či prechádza scripts/audit_db.py
- každú tabuľku z sb.from('...') v kóde porovnaj s migráciami: má RLS + aspoň jednu policy?
- citlivé zbery v kóde (geolocation, GPS, kamera, kontakty) vs. či ich legal.html výslovne deklaruje — každý nesúlad je nález
- dátumy "Last updated" vo všetkých dokumentoch vs. realita kódu (zastarané dokumenty vymenuj)
- počty: recepty, ingrediencie (verified vs. estimated), jazyky UI, AI call sites cez proxy

## Krok 3 — Krížová kontrola dokumentov (rozpory)
Porovnaj navzájom: MVP_DEFINITION vs. skutočné moduly · ROADMAP tabuľka vs. log vs. status.html · cenník v presentation vs. FOUNDING_OFFER · sľuby v legal.html a PILOT_AGREEMENT vs. funkcie a monetizačné modely · NEBENERWERB/blokátory vs. ich reálny stav. Každý rozpor: čo hovoria, prečo to vadí, oprava.

## Krok 4 — Analýza a verdikty
1. Lístok 00 — Delta: nájdi najnovší visual data/CRITICAL_REVIEW/CRITICAL_REVIEW_*.html, vyčítaj z neho vtedajší stav a kvadrant „urob tento týždeň" a vyhodnoť, čo sa odvtedy pohlo/nepohlo (skóre X/Y hotových úloh). Ak žiadny starý report nie je, napíš to a deltu vynechaj.
2. Executive summary: silné stránky / slabiny / príležitosti / riziká + čo si investor všimne za 5 minút.
3. Moduly 1–10 s pečiatkami FIRE (investuj) / HOLD (drž, nerozširuj) / 86 (škrtni) + redizajn s najväčšou pákou pre každý.
4. Matica priorít 2×2 (dopad × námaha) — konkrétne úlohy, hotové z minula prečiarkni.
5. Stav blokátorov príjmu a trialu: Nebenerwerb, Einzelfirma/AHV, mailer/login cudzou adresou, regresný prechod na zariadeniach, obnova zálohy, fronta nespustených migrácií, tlačiareň. Ak stav nevieš zistiť zo súborov, napíš „neoveriteľné z repa — potvrď" namiesto hádania.
6. Master plán na najbližšie 4 týždne, kapacitne úprimný (80 % práca v kuchyni, ~10–12 h/týždeň).

## Krok 5 — Výstup
Vytvor JEDEN self-contained HTML súbor: visual data/CRITICAL_REVIEW/CRITICAL_REVIEW_<dnešný dátum RRRR-MM-DD>.html (starý neprepisuj — delta ho potrebuje). Potom skopíruj nový report aj do visual data/CRITICAL_REVIEW/latest.html (prepíš) — Internal Docs v appke ukazuje trvalo na latest.html, takže odkaz sa nikdy nemení.
Dizajn = ChefOS systém: pozadie #0A1A2F, karty #122845, linky #223d57, teal #34F7D7, zlatá #F7C948, červená pre riziká; serif italic nadpisy, mono pre dáta; sekcie ako „LÍSTOK 01…16" s expo pečiatkami; CSS bar-charty a tabuľky, žiadne externé JS knižnice; mobil-first.
Pravidlá poctivosti: žiadne vymyslené čísla — každý odhad označ ako odhad; ceny konkurencie a valuácie len ako orientačné pásma; čo si nevedel overiť, povedz v reporte.
Na záver mi do chatu napíš 5-riadkové zhrnutie: 3 najväčšie posuny, 2 najväčšie diery.
