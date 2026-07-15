#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ChefOS DB migration auditor — the permanent guard for the multi-tenant bug class.

Scans every db/*.sql migration and fails loudly when:
  1. a table is created WITHOUT a kitchen_id column (unless whitelisted as
     deliberately global/per-user),
  2. a table is created without `enable row level security`,
  3. a table has RLS enabled but no policy is ever defined for it,
  4. migration numbers are duplicated (two files claiming the same number),
  5. a migration contains a destructive statement (DROP TABLE, TRUNCATE,
     DELETE without WHERE) that isn't explicitly acknowledged with a
     `-- DESTRUCTIVE: <reason>` comment in the same file,
  6. an RLS policy created ON table X subqueries X itself inside its own
     USING/WITH CHECK body — Postgres re-applies X's policies to that inner
     subquery and recurses until error 42P17, which poisons EVERY query
     against the table for EVERY user (a full outage of anything touching
     it). The fix is always the same: move the lookup into a SECURITY
     DEFINER function (see my_kitchen_id() in db/55). This exact bug shipped
     TWICE — db/53 (2026-07-13, full-app outage) and db/86 (2026-07-16,
     locked the super-admin out of his own account) — which is why it is now
     a hard check and not a code-review memory.

Why this exists (health check 2026-07-15): ChefOS had three real RLS incidents
in one week (db/53 recursion outage, db/62 column-grant lockout, the pre-db/34
open-access era). Every one shipped because nothing checked migrations
automatically before they reached the SQL editor. This script is that check —
run locally via .githooks/pre-commit and in CI on every push.

Exit code 0 = clean, 1 = violations found.
"""
import re
import sys
import glob
import os
from collections import defaultdict

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB = os.path.join(REPO, 'db')

# Tables that legitimately have no kitchen_id:
#   - profiles: per-user row keyed by auth.uid(), carries kitchen_id as a FK member pointer
#   - kitchens: IS the tenant table
#   - user_settings: per-user (API keys), keyed by user id
#   - confidentiality_acceptances: per-user legal record, deliberately append-only
#   - kitchen_invites: keyed by kitchen_id? (it has one; listed here only if not)
NO_TENANT_OK = {
    'profiles',                    # per-user row keyed by auth.uid(); carries kitchen_id as membership pointer
    'kitchens',                    # IS the tenant table
    'user_settings',               # per-user (API keys), keyed by user id
    'confidentiality_acceptances', # per-user legal record, append-only
    'favorites',                   # per-user (user_id PK half), RLS own-rows
    'recipe_notes',                # per-user (user_id PK half), RLS own-rows
    'access_requests',             # platform access gate — exists BEFORE the user has any kitchen
    'profile_private',             # per-user sensitive columns (db/69 draft), keyed by user id
    'email_contacts',              # ChefOS-operator outreach list, not per-kitchen data
    'chef_connections',            # person-to-person, not kitchen-to-kitchen (db/84)
    'app_config',                  # single-row global app setting (coming-soon wall), not tenant data at all (db/96)
}

# Tables allowed to skip RLS entirely (none today — keep empty on purpose).
NO_RLS_OK = set()

# Historical migrations that contain the self-referencing-policy bug and are ALREADY
# superseded by a later fix migration. They stay in the repo as an accurate record of what
# ran on production (rewriting an applied migration would make the repo lie about history),
# so the recursion check skips exactly these files and nothing else.
RECURSIVE_POLICY_SUPERSEDED = {
    '53_invite_expiry_and_remove_member.sql',  # fixed by db/55 (2026-07-13 outage)
    '86_admin_permissions_rls.sql',            # fixed by db/90 (2026-07-16 super-admin lockout)
}

create_re = re.compile(r'create\s+table\s+(?:if\s+not\s+exists\s+)?([a-z_]+)\s*\(', re.I)
enable_rls_re = re.compile(r'alter\s+table\s+([a-z_]+)\s+enable\s+row\s+level\s+security', re.I)
policy_re = re.compile(r'create\s+policy\s+.+?\s+on\s+([a-z_]+)', re.I)
# Whole CREATE POLICY statement, so the body can be inspected for self-reference. Policy
# bodies never contain a semicolon (they're a single USING/WITH CHECK expression), so
# non-greedy up to ";" captures exactly one statement.
policy_stmt_re = re.compile(r'create\s+policy\s+"[^"]+"\s+on\s+([a-z_]+)(.*?);', re.I | re.S)
destructive_re = re.compile(r'\b(drop\s+table|truncate\s+table|truncate\s+[a-z_]+\s*;)', re.I)
delete_re = re.compile(r'\bdelete\s+from\s+([a-z_]+)\s*;', re.I)  # DELETE with no WHERE before ;

def strip_comments(sql):
    sql = re.sub(r'--[^\n]*', '', sql)
    sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.S)
    return sql

def main():
    files = sorted(glob.glob(os.path.join(DB, '[0-9]*.sql')))
    if not files:
        print('audit_db: no migrations found — wrong directory?')
        return 1

    violations = []
    created = {}          # table -> file where created
    rls_enabled = set()
    has_policy = set()
    numbers = defaultdict(list)

    for path in files:
        base = os.path.basename(path)
        m = re.match(r'(\d+)', base)
        if m:
            numbers[int(m.group(1))].append(base)
        raw = open(path, encoding='utf-8', errors='replace').read()
        sql = strip_comments(raw)

        for t in create_re.findall(sql):
            created.setdefault(t.lower(), base)
            # find the create block to check for kitchen_id
            block_m = re.search(r'create\s+table\s+(?:if\s+not\s+exists\s+)?' + t + r'\s*\((.*?)\);', sql, re.I | re.S)
            block = block_m.group(1) if block_m else ''
            if t.lower() not in NO_TENANT_OK and 'kitchen_id' not in block.lower():
                violations.append(f'{base}: table "{t}" created WITHOUT kitchen_id — every tenant-scoped table must carry it (whitelist in scripts/audit_db.py if genuinely global)')
        for t in enable_rls_re.findall(sql):
            rls_enabled.add(t.lower())
        for t in policy_re.findall(sql):
            has_policy.add(t.lower())

        if base not in RECURSIVE_POLICY_SUPERSEDED:
            for t, body in policy_stmt_re.findall(sql):
                if re.search(r'\bfrom\s+' + re.escape(t) + r'\b', body, re.I):
                    violations.append(
                        f'{base}: policy on "{t}" subqueries "{t}" inside its own body — '
                        f'infinite RLS recursion (42P17), breaks every query on the table for everyone. '
                        f'Use a SECURITY DEFINER helper instead (pattern: my_kitchen_id() in db/55). '
                        f'This exact bug caused the db/53 outage AND the db/86 admin lockout.'
                    )

        for m2 in destructive_re.finditer(sql):
            if '-- DESTRUCTIVE:' not in raw:
                violations.append(f'{base}: destructive statement "{m2.group(1)}" without an explicit "-- DESTRUCTIVE: <reason>" acknowledgement comment')
        for t in delete_re.findall(sql):
            if '-- DESTRUCTIVE:' not in raw:
                violations.append(f'{base}: DELETE FROM {t} with no WHERE clause and no "-- DESTRUCTIVE:" acknowledgement')

    for t, origin in created.items():
        if t in NO_RLS_OK:
            continue
        if t not in rls_enabled:
            violations.append(f'{origin}: table "{t}" never gets "enable row level security" in any migration')
        elif t not in has_policy:
            violations.append(f'{origin}: table "{t}" has RLS enabled but no policy is ever created — that silently blocks ALL access (or none, if RLS gets disabled later)')

    for n, names in sorted(numbers.items()):
        if len(names) > 1:
            violations.append(f'duplicate migration number {n:02d}: {", ".join(names)}')

    if violations:
        print(f'audit_db: {len(violations)} violation(s):')
        for v in violations:
            print('  ✗ ' + v)
        return 1
    print(f'audit_db: clean — {len(files)} migrations, {len(created)} tables, all tenant-scoped or whitelisted, all with RLS + policies.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
