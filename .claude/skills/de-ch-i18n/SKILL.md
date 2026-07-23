---
name: de-ch-i18n
description: Extract hardcoded UI strings from the Sautero single-file HTML app into the i18n catalogue and translate them into Swiss High German (de-CH) for professional kitchen staff. Use this skill whenever the user mentions translation, German, de-CH, i18n, localisation, "Übersetzung", untranslated UI, a new screen/modal/button that needs text, or whenever new user-facing strings are added to the app — even if the user does not say the word "translation". Also use it before any release that touches the UI, to check translation coverage.
---

# Swiss German (de-CH) i18n for Sautero

Sautero serves professional kitchens in German-speaking Switzerland. German is the
**primary** locale, not an afterthought. English is the fallback/dev locale.

The app is a single-file HTML application. That constrains how i18n is done — read
"Mechanics" before touching anything.

## Hard rules (never violate)

1. **No `ß` ever.** Swiss orthography uses `ss`. `Strasse`, `gross`, `Fussboden`, `Masse`.
2. **Sie-Form, always.** Never `du`. Kitchen software is a work tool, not a consumer app.
3. **Glossary is law.** Terms in `references/glossary.md` are locked. Never invent a
   synonym for a term that already has an entry. If a needed term is missing, add it to
   the glossary in the same change and tell the user.
4. **Never translate user data.** Recipe names, ingredient names, supplier names,
   allergen free-text and anything stored in Supabase is user content. Translate only
   chrome: labels, buttons, headings, tooltips, errors, empty states, confirmations.
5. **Never translate keys, console logs, code comments, or Supabase column names.**
6. **Never edit `db/`, migrations, or RLS policies from this skill.** UI strings only.

## Swiss formatting

| Thing | Correct | Wrong |
|---|---|---|
| Money | `CHF 12.50` | `12,50 €`, `12.50 CHF` |
| Thousands | `1'250.00` | `1.250,00`, `1,250.00` |
| Decimal | `.` (point) | `,` |
| Date | `23.07.2026` | `07/23/2026` |
| Time | `14:25` (24h) | `2:25 PM` |
| Weight | `1.5 kg`, `250 g` | `1,5 kg` |
| Temperature | `4 °C` (space before °C) | `4°C` |

Use `Intl.NumberFormat('de-CH')` and `Intl.DateTimeFormat('de-CH')` rather than hand-rolled
formatting. Never hardcode a formatted number inside a translation string.

## Mechanics (single-file HTML)

The app has one i18n catalogue near the top of the file:

```js
const I18N = {
  de: { /* primary */ },
  en: { /* fallback */ }
};
const LOCALE = localStorage.getItem('sautero.locale') || 'de';
const t = (key, vars) => { /* lookup with {placeholder} interpolation, falls back to en, then key */ };
```

Markup uses attributes so the DOM can be re-labelled without re-rendering:

```html
<button data-i18n="prep.board.add">Aufgabe hinzufügen</button>
<input data-i18n-placeholder="recipe.search.placeholder">
<span data-i18n-title="haccp.temp.tooltip"></span>
```

`applyI18n(root)` walks `root` and sets `textContent` / `placeholder` / `title` from the
catalogue. Call it after any dynamic render.

**Editing discipline:** this file is large. Make anchored, surgical edits only. Never
rewrite a whole section or reformat surrounding code. One logical change per pass. If a
change would touch more than ~200 lines, stop and report to the user instead.

## Key naming

`module.component.element[.state]` — lowercase, dot-separated, English.

```
recipes.editor.save
recipes.editor.save.pending
prep.board.empty.title
haccp.label.print.error.printer_offline
orders.supplier.select.placeholder
```

Rules: never reuse one key in two contexts just because the English matches — German
often diverges (`Speichern` vs `Sichern` vs `Übernehmen`). Never build keys by string
concatenation at runtime; the coverage script must be able to find them statically.

## Placeholders and plurals

- Placeholders: `{count}`, `{name}`, `{unit}`. Never split a sentence into concatenated
  fragments — German word order differs from English.
  - Good: `"prep.tasks.remaining": "Noch {count} Aufgaben offen"`
  - Bad: `t('prep.still') + count + t('prep.tasks_open')`
- Plurals: use `Intl.PluralRules('de-CH')` with `_one` / `_other` key suffixes when the
  count can be 1.
- Never put HTML tags inside a translation string. Split the string or use placeholders.

## Workflow

When asked to translate a screen, module, or the whole app:

1. **Scan.** Find hardcoded user-facing strings in the target scope. Report the count
   before changing anything. Look in: HTML text nodes, `placeholder`/`title`/`aria-label`
   attributes, `alert()`/`confirm()`/toast calls, template literals in render functions,
   and error-handling branches (these are the most commonly missed).
2. **Confirm scope.** If more than ~40 strings, propose a module-by-module order and let
   the user pick. Do not attempt the whole app in one pass.
3. **Extract.** Add keys to `I18N.en` with the existing English text verbatim. Replace
   the hardcoded occurrences with `data-i18n` attributes or `t()` calls.
4. **Translate.** Add the `de` entries using the glossary. Read
   `references/glossary.md` before writing any German.
5. **Verify.** Run the checks below.
6. **Report.** State: strings extracted, de coverage before/after, glossary terms added,
   anything deliberately left untranslated and why.

## Verification checklist

Before reporting done, confirm every item:

- [ ] `grep -c 'ß'` on the de catalogue returns 0
- [ ] No `\bdu\b`, `\bdein`, `\bdich\b` in de strings (case-insensitive)
- [ ] Every key present in `en` is present in `de` (list any gaps explicitly)
- [ ] Every `data-i18n` attribute in the markup resolves to an existing key
- [ ] No key is defined twice
- [ ] Placeholder sets match between `en` and `de` for each key
- [ ] No currency, date, or number formatting baked into a string literal
- [ ] Glossary terms used consistently — no synonym drift
- [ ] German strings are not more than ~1.4× the English length in tight UI spots
      (buttons, table headers, mobile nav). German runs long; flag overflow risks with
      the specific key so the user can shorten or adjust CSS.

## Length discipline

Kitchen staff use this on a phone or a wall tablet with wet hands. Prefer the short,
idiomatic professional term over a literal translation:

- `Speichern` not `Änderungen speichern und fortfahren`
- `Rüstliste` not `Liste der vorzubereitenden Zutaten`
- `Charge` not `Produktionsstapel`

Never sacrifice a glossary term to save characters — shorten the surrounding words instead.

## Tone

Written by a chef, for chefs. Direct, professional, imperative in buttons
(`Speichern`, `Drucken`, `Löschen`), neutral in messages. No exclamation marks, no
marketing voice, no apologising. Errors say what happened and what to do:

- Good: `Etikett konnte nicht gedruckt werden. Drucker prüfen und erneut versuchen.`
- Bad: `Ups! Da ist leider etwas schiefgelaufen 😕`

## Reference

- `references/glossary.md` — locked gastronomy and HACCP terminology. **Read this before
  writing any German string.** Contains the canonical term, gender/article, plural, and
  forbidden alternatives.
