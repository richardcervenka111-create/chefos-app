# Sautero — Security & Legal Review Package (16 July 2026)

This folder exists so a lawyer (and, eventually, a professional security auditor) can review
what Sautero actually does today, before the public trial / paid launch. Nothing in here has
been reviewed by a lawyer yet — it's Claude's best effort based on public information about
GDPR and the Swiss Federal Act on Data Protection (nDSG/revFADP, in force since Sept 2023), not
legal advice.

## What to review

- **`../app/legal.html`** — the live, in-app "Privacy & Terms" page. This is the canonical
  document (don't create a separate copy here — review it in place so there's only ever one
  source of truth). Users must now explicitly accept a summary of it before using the app (see
  "The consent gate" below).
- **`SECURITY_REVIEW_2026-07-16.md`** — a technical self-review of the app's access-control
  model (Row Level Security), written today, covering both what's solid and what's still a known
  gap.

## The consent gate (new today, db/100_privacy_consent.sql)

Every user — including people already using the app — now has to explicitly accept a
plain-language privacy summary (shown in-app, mirrors `legal.html`) before they can continue.
Acceptances are logged permanently and versioned (`privacy_acceptances` table, mirrors the
existing `confidentiality_acceptances` mechanism from 13 July). If `legal.html` changes
materially, bump `PRIVACY_VERSION` in `app/index.html` and everyone will be asked to re-agree —
the old acceptance record stays as permanent proof of what they agreed to and when.

## Known open items (not blockers to review, but worth knowing)

- No official Data Processing Agreement (DPA) exists yet with Supabase or Anthropic on file —
  both are standard SaaS vendors with their own DPAs available on request; worth formally
  countersigning before real customer data (beyond the current invited trial) flows through.
- No cookie/consent banner exists because Sautero doesn't use tracking cookies or third-party
  analytics (stated in `legal.html`) — confirm this claim stays true as features are added.
- Switzerland vs. EU: Sautero is currently framed as subject to both regimes since it may serve
  kitchens in either. A lawyer should confirm whether Swiss law, EU GDPR, or both actually apply
  given where Sautero (the company) and its users are based once that's finalized (see the
  Nebenerwerb/Einzelfirma paperwork already in progress).
- The Working Time / hours data now has a real admin-read path (Kitchen Reports, 16 July) gated
  behind explicit per-employee consent — see the RLS policy in
  `../db/99_kitchen_reports.sql` and the writeup in `SECURITY_REVIEW_2026-07-16.md`.
