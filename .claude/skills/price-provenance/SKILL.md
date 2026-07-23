---
name: price-provenance
description: Enforce source tracking on every ingredient price in Sautero — verified supplier data, AI estimate, or manual entry — with a date and confidence. Use this skill whenever the user touches ingredient prices, food cost, margins, supplier data, price imports, or the pricing UI; whenever a price is written, updated, seeded, or displayed; and whenever the user mentions "AI estimated", "wrong price", "outdated price" or asks why a food cost number looks off. Also use it before any release that changes pricing logic.
---

# Price Provenance

A food cost number is only as trustworthy as its worst input. Sautero currently leans on
AI-estimated prices — that is the single fastest way to lose a pilot chef, because a chef
knows what he pays for butter and will spot a wrong number in five seconds. When he does,
he stops trusting the whole app, not just that field.

The fix is not "get better estimates". It is **never show a number without saying where it
came from.**

## The contract

Every price record carries these fields. No exceptions, no defaults that hide the truth.

| Field | Type | Meaning |
|---|---|---|
| `value` | numeric | Price in CHF |
| `unit` | text | Base unit (`kg`, `l`, `Stk`) |
| `source` | enum | `supplier_verified` \| `supplier_listed` \| `manual` \| `ai_estimate` |
| `source_ref` | text \| null | Invoice no., supplier price list ID, URL, or null |
| `captured_at` | timestamptz | When this price was true |
| `captured_by` | uuid \| null | User who entered/confirmed it |

### Source levels

- **`supplier_verified`** — taken from an actual invoice or delivery note for this tenant.
  Highest trust. Requires `source_ref`.
- **`supplier_listed`** — from a published supplier price list (Pistor, Transgourmet,
  Prodega, Saviva). Requires `source_ref`. Trustworthy but not tenant-specific.
- **`manual`** — the chef typed it in. Trusted for that tenant, but no audit trail.
- **`ai_estimate`** — generated. **Never trusted. Always visibly marked. Never counted as
  a real cost in any exported or printed document.**

## Hard rules

1. **No write without provenance.** Any code path that inserts or updates a price must set
   `source` and `captured_at`. If you cannot determine the source, the write does not
   happen — do not default to `manual` to make it pass.
2. **`ai_estimate` never upgrades itself.** Only an explicit user confirmation or a
   supplier import may change `source` to a higher level. Never silently promote.
3. **Never overwrite a higher-trust price with a lower one.** A new `ai_estimate` must not
   replace an existing `supplier_verified` value. Keep the better one, record the conflict.
4. **Never delete history.** Price changes append; they do not mutate in place. Food cost
   from March must still be reproducible in July.
5. **Never let an estimate leave the building unmarked.** Exports, PDFs, printed recipe
   cards and supplier orders either exclude `ai_estimate` rows or label them explicitly.
6. **Never invent a price.** If asked to seed or backfill data and no real source exists,
   write `ai_estimate` with an honest `source_ref` of `null` — do not fabricate an
   invoice number, a supplier name, or a plausible-looking figure presented as real.

## UI requirements

Every displayed price shows its provenance without the user having to hunt for it.

| Source | Indicator | Behaviour |
|---|---|---|
| `supplier_verified` | no badge (this is the norm) | — |
| `supplier_listed` | subtle badge, supplier name | tooltip shows list date |
| `manual` | subtle badge | tooltip shows who + when |
| `ai_estimate` | **visible warning badge** | tooltip: „Geschätzter Preis — bitte prüfen" |

Aggregates (recipe cost, margin, dashboard totals) that include **any** `ai_estimate`
input must carry the warning badge too. A clean-looking total built from dirty inputs is
worse than no total.

Staleness: prices older than 90 days show a "veraltet" indicator regardless of source.
Fresh produce should be tighter — 30 days — if the ingredient category supports it.

## Workflow

When asked to work on pricing:

1. **Audit first.** Report the current distribution: how many prices per source level,
   how many stale, how many recipes contain at least one `ai_estimate`. Numbers before
   opinions.
2. **Identify the write paths.** List every place a price can enter the system (import,
   manual form, AI scanner, seed script, migration). Any path missing provenance is a bug
   — report it before fixing anything else.
3. **Fix writes before reads.** No point labelling the UI if new bad data keeps arriving.
4. **Then the UI.** Badges, tooltips, aggregate propagation.
5. **Then the migration** for existing rows: everything without a known source becomes
   `ai_estimate` with `source_ref = null`. Do not guess retroactively.

## Verification

- [ ] Every price write path sets `source` and `captured_at`
- [ ] No code path defaults `source` to anything other than `ai_estimate`
- [ ] No promotion of `ai_estimate` without explicit user action
- [ ] Aggregates propagate the worst source level of their inputs
- [ ] Exports mark or exclude estimates
- [ ] Existing rows migrated honestly, not backfilled with invented sources
- [ ] German labels follow the `de-ch-i18n` glossary (`geschätzter Preis`,
      `verifizierter Preis`, `Einstandspreis`)

## Note for the user

The correct end state is not "all prices verified" — that is unreachable for a solo
founder. It is "the chef always knows which numbers he can trust." An app that says
"this one is a guess, check it" is more credible than one that quietly guesses everywhere.
Say so plainly if the user starts optimising for coverage instead of honesty.
