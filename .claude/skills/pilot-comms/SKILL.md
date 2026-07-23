---
name: pilot-comms
description: Write German communications to Sautero's pilot restaurants — release notes, incident and downtime notices, data-issue disclosures, onboarding messages, feedback requests and pricing changes. Use this skill whenever the user needs to tell a pilot customer something: a new feature shipped, something broke, data was wrong, a migration is coming, an outage happened, or feedback is needed. Also use it whenever the user drafts an email or message to a chef, restaurant, or pilot establishment.
---

# Pilot Comms

The audience is a working Küchenchef in a Swiss kitchen. He reads this on a phone between
service periods, in German, and he does not care about your architecture. He cares about
two things: does it affect tonight's service, and does he have to do anything.

Write for that person.

## Language

German, always. Swiss High German — no `ß`, Sie-Form, Swiss number and date formats.
Follow `de-ch-i18n/references/glossary.md` for terminology so the email matches the app.
Never mix English feature names into German prose unless the UI itself uses them.

## Structure

Every message, regardless of type, answers in this order:

1. **What happened / what is new** — one sentence, first line, no wind-up
2. **What it means for him** — concrete, in kitchen terms not software terms
3. **What he has to do** — explicitly "nichts" if nothing
4. **When** — a real date, not "bald" or "in Kürze"

Length: release notes under 150 words, incident notices under 100. If it is longer, it is
not finished.

Subject lines say the thing. `Sautero: Etikettendruck war gestern Abend gestört` — not
`Sautero Update` or `Wichtige Mitteilung`.

## Register

- Sie, professional, plain. A chef-to-chef register, not a support-desk one.
- No exclamation marks. No emoji. No "Wir freuen uns, Ihnen mitteilen zu dürfen".
- No apologising in a loop. Once, plainly, then move to the facts.
- No hedging that hides the answer: not "es kann in seltenen Fällen vorkommen, dass" but
  "Zwischen 18:00 und 19:20 konnten keine Etiketten gedruckt werden."
- Never blame the user, the browser, the printer or Supabase.
- Never say "bekanntes Problem" without a date by which it will be fixed.

## Translating engineering into kitchen

| Do not write | Write |
|---|---|
| Migration deployed | Ab Montag sind die Rezepte nach Posten sortiert |
| RLS policy fixed | Ihre Daten waren zu keinem Zeitpunkt für andere Betriebe sichtbar |
| Deploy gate failed | Das Update kommt eine Woche später |
| AI-estimated prices | Geschätzte Preise — bitte vor der Kalkulation prüfen |
| XSS vulnerability | Eine Sicherheitslücke wurde geschlossen |
| Downtime | Die App war von 18:00 bis 19:20 nicht erreichbar |

## Incident and data-issue notices

These are the ones that decide whether a pilot renews. Rules:

- **Send it before he notices, or as soon as possible after.** Late disclosure costs more
  trust than the incident.
- **State the actual window** with real times. Vagueness reads as concealment.
- **Say whether data was lost or wrong**, plainly. If prices or HACCP records were
  affected, say which and over what period — that is a documentation obligation for him,
  not just an inconvenience.
- **Never claim data was safe unless it has been verified.** If it is still being checked,
  say that and give a time for the follow-up.
- **One concrete prevention step**, not a paragraph about commitment to quality.
- No compensation offers or contractual promises without the user's explicit instruction.

## Feature announcements

Only announce what is live in production for that tenant. Never announce staging, never
pre-announce a date you are not certain of — a missed date from a solo founder is more
damaging than silence. One feature per message beats a changelog dump.

## Before sending

- [ ] Every factual claim in the message is true today — if in doubt, run `claim-check`
- [ ] No `ß`, no `du`, Swiss date/number formats
- [ ] Terminology matches the app's German UI
- [ ] The required action is stated, even if it is "nichts"
- [ ] A real date appears wherever timing is mentioned
- [ ] Under the word limit
- [ ] Nothing promises an SLA, uptime figure, or legal guarantee

## Ask before writing

If the user has not said, ask: which pilot(s), channel (email / WhatsApp — many chefs
prefer it), and whether this goes to the Küchenchef or the owner. The register differs:
the chef wants operational impact, the owner wants cost and risk.
