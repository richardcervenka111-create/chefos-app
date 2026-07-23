---
name: rls-guard
description: Review every Supabase table, storage bucket, RLS policy, RPC function and client query in Sautero for multi-tenant isolation before it can ship. Use this skill whenever the user creates or alters a table, bucket, policy, view, trigger or database function; whenever a migration is written; whenever user-generated content is rendered; and whenever the user mentions RLS, security, permissions, tenant, leak, XSS, storage, or asks whether something is safe to deploy. Also use it as part of any pre-release audit.
---

# RLS Guard

Sautero is multi-tenant: several restaurants share one Supabase project. One tenant seeing
another tenant's recipes, costs, staff hours or HACCP records is not a bug — it is the end
of the company. Two real findings already occurred (a public storage bucket and a stored
XSS). Assume there are more.

The anon key is public. It ships in a single-file HTML app on GitHub Pages. **Anyone can
read it and query the database directly.** Every protection must live in the database, not
in the client.

## The isolation rule

Every row belongs to exactly one tenant, and every table proves it.

```sql
tenant_id uuid not null references tenants(id)
```

No nullable `tenant_id`. No "shared" rows without an explicit, reviewed exception. No
table where tenancy is implied by a join two levels away — the policy must be able to
decide from the row itself or via a single indexed lookup.

## Non-negotiables

1. **RLS enabled on every table in `public`.** A table without RLS is world-readable with
   the anon key. `alter table x enable row level security;` is not optional.
2. **RLS enabled is not RLS enforced.** A table with RLS on and no policies denies
   everything; a table with a policy of `using (true)` denies nothing. Read the policy body.
3. **Separate policies per operation.** `select`, `insert`, `update`, `delete` each get
   their own. An `insert` policy without a `with check` clause lets a user write rows into
   another tenant.
4. **`update` needs both `using` and `with check`.** `using` controls which rows can be
   touched; `with check` controls what they can be changed into. Missing `with check`
   allows a tenant to move a row to another tenant.
5. **Never trust a client-supplied `tenant_id`.** Derive it from `auth.uid()` inside the
   policy. If the client sends it, the policy must verify it matches, not accept it.
6. **`security definer` functions bypass RLS.** Every one is a potential hole. Require an
   explicit justification, a fixed `search_path`, and internal tenant checks. Default to
   `security invoker`.
7. **Storage buckets are tables too.** Private by default. Path convention
   `{tenant_id}/{...}` with a policy matching the first path segment against the user's
   tenant. Never public unless the content is genuinely public marketing material.
8. **Signed URLs expire.** No indefinite public links to tenant content.

## The XSS side

Same trust boundary, different direction: data written by one user is rendered to another.

- **Never `innerHTML` with user content.** `textContent` for text, `createElement` +
  properties for structure. This is a single-file HTML app with no framework escaping —
  nothing catches it for you.
- Recipe names, ingredient names, notes, supplier names, HACCP comments, staff names,
  allergen free-text: all attacker-controlled from the app's point of view.
- Never interpolate user content into `href`, `src`, `style`, `on*` attributes, or into a
  template literal that becomes markup.
- Sanitise on render, not only on write. Data already in the database may predate the fix.
- File uploads: validate type server-side, never serve user uploads from the app origin
  with an inline content-disposition.

## Review procedure

Run this on any change touching the database or rendering user content:

1. **Enumerate the surface.** New/changed tables, buckets, policies, functions, views,
   triggers, and any new render path for user content. State the list before analysing.
2. **Per table, answer explicitly:**
   - Is RLS enabled?
   - Is there a policy for each of select/insert/update/delete that the app actually uses?
   - Does each policy derive tenancy from `auth.uid()`?
   - Does `insert` have `with check`? Does `update` have both clauses?
   - Is `tenant_id` `not null` and indexed?
3. **Per function:** `security definer`? Justified? `search_path` pinned? Tenant check inside?
4. **Per bucket:** public flag, path convention, policy, URL expiry.
5. **Per render path:** `innerHTML` present? User content in attributes?
6. **Write the negative test.** Every isolation claim needs a test that logs in as tenant B
   and confirms it *cannot* read/write tenant A's row. A passing positive test proves
   nothing about isolation.
7. **Report.** Findings by severity, each with the exact file/line and the fix. If clean,
   say so plainly — do not manufacture findings.

## Verdict

End with one of exactly these:

- **PASS** — no isolation gaps found, negative tests present and passing.
- **PASS WITH NOTES** — no gaps, but hardening recommended (listed).
- **BLOCK** — at least one gap. Must not reach the deploy gate.

Never soften a BLOCK because the change is small, urgent, or "only internal". The two
findings already in the health log both looked small.

## Interaction with the deploy gate

Isolation tests belong in the lock suite, not in a manual checklist. If a new table has no
corresponding negative test in the suite, that is itself a BLOCK — the gate must be able to
catch a regression without a human remembering to look.
