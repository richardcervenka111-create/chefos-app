---
name: claim-check
description: Verify that every factual claim in Sautero's legal, marketing, pilot and investor material is true of the code as it exists today. Use this skill whenever the user writes or edits a pilot agreement, terms of service, privacy policy, DPA, AVV, landing page, pitch deck, feature list, onboarding email or funding application; whenever the user mentions compliance, GDPR, DSG, revDSG, data processing, SLA, uptime, encryption, backups, certification; and whenever a document states what the product does. Also use it before sending anything to a customer, lawyer, employer or investor.
---

# Claim Check

Sautero's legal documents already contain verifiable inaccuracies. That is a specific,
serious category of risk: a customer-facing document that describes a feature the code does
not have is not a typo — it is a misrepresentation, and in a DPA or privacy policy it is
also a regulatory exposure.

This skill's job is to be the person who asks "is that actually true?" about every sentence.

## Scope of a claim

A claim is any sentence a reasonable reader would take as a statement of fact about the
product, the company, or the data. Examples of claims:

- "Data is encrypted at rest and in transit"
- "Backups are performed daily"
- "We do not share data with third parties"
- "Hosted in Switzerland"
- "99.9 % availability"
- "Recipes are private to your establishment"
- "Sautero GmbH"
- "ISO / HACCP compliant"
- "Supports up to 25 users"

Marketing adjectives ("intuitive", "fast", "built by chefs") are not claims. Numbers,
capabilities, locations, legal entities, certifications and guarantees are.

## Verdicts

Classify every claim as exactly one of:

- **TRUE** — verified against code, config, or a document you have read. Cite where.
- **FALSE** — contradicted by the implementation. Must be removed or corrected.
- **UNVERIFIABLE** — may be true, but nothing in the repo proves it. Treat as FALSE for
  external documents until evidence exists.
- **ASPIRATIONAL** — true of the roadmap, not of today. Must be rewritten in future tense
  and clearly marked, or removed.

Never mark something TRUE because it is probably true, because Supabase probably does it,
or because it is standard practice. Verify or downgrade.

## Known danger areas for Sautero

Check these every time — they are where the errors cluster:

| Claim area | What to actually verify |
|---|---|
| Legal entity | Is there one? Einzelfirma registered? AHV? Signing as a natural person means the document must say so. Never write "GmbH" until it exists. |
| Data location | Which Supabase region? Is it actually Switzerland/EU? Does the privacy policy match? |
| Sub-processors | Supabase, GitHub, Anthropic, any AI provider, email sender. **All must be named** in the DPA. An unlisted sub-processor is a straightforward violation. |
| AI processing | If recipe or supplier data goes to an AI API, the document must say so. Silence here is the most common and most damaging omission. |
| Encryption | At rest = Supabase default; in transit = HTTPS. Verify, then state precisely — do not upgrade to "end-to-end". |
| Backups | Does a backup actually exist, on what schedule, tested restore? If never tested, do not promise restoration. |
| Uptime / SLA | A solo founder on GitHub Pages should promise no SLA. Any percentage is a liability. |
| Liability exclusion | Swiss law limits what can be excluded. A blanket exclusion is likely unenforceable and signals sloppiness. |
| IP ownership | Must be explicit. Also must not conflict with the Nebenerwerb disclosure to the employer. |
| Language | German-language market. An English-only contract is a real enforceability risk — flag it every time. |
| Feature lists | Every listed feature must exist and work in production, not staging. |
| Testimonials / logos | Written consent from the pilot establishment on file? |

## Procedure

1. **Extract.** List every claim in the document as a numbered table. Do not paraphrase
   away the strong version of a claim — quote the operative phrase.
2. **Verify.** For each, find evidence in the repo, config, or a document. Search rather
   than assume. State the evidence path.
3. **Classify.** TRUE / FALSE / UNVERIFIABLE / ASPIRATIONAL.
4. **Propose the corrected sentence** for anything not TRUE. A weaker true sentence always
   beats a stronger false one.
5. **Summarise:** counts by verdict, then the FALSE list first, in order of consequence.

## Tone with the user

Be direct about findings. This is a solo founder shipping to real restaurants — softening a
FALSE into a "maybe worth revisiting" is not kindness, it is how a document reaches a
customer uncorrected. State what is wrong, why it matters, and what to write instead.

## Boundary

This skill checks whether claims match reality. It does not give legal advice, does not
judge whether a clause is enforceable beyond flagging obvious risk, and does not replace a
Swiss lawyer for the pilot agreement, DPA or terms. Say so when the user starts treating
the output as legal sign-off.
