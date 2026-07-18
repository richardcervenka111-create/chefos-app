# db/ — Migration rules (the contract)

Established by the 2026-07-15 health check. These rules are partly **enforced by
machines** — `scripts/audit_db.py` runs in every git hook and in CI and fails the
commit/push/deploy on violation.

1. **Every schema change is a numbered file here.** Never type ad-hoc SQL into the
   Supabase editor for anything you want to keep — if it's not in a `db/NN_*.sql` file,
   it doesn't exist.
2. **Numbers never repeat.** Check the highest existing number first.
   *(Enforced: audit_db.py fails on duplicates.)*
3. **Staging first** for anything that touches data or constraints. Pure new tables and
   pure function/policy redefinitions may go straight to production; anything that
   UPDATEs, DELETEs, backfills or changes constraints runs on `chefos-staging` first.
   State the class in the file header.
4. **Every new table carries `kitchen_id`** unless genuinely per-user/global — then add
   it to the whitelist in `scripts/audit_db.py` *with a reason*.
   *(Enforced: audit_db.py fails otherwise.)*
5. **Every new table gets RLS enabled AND at least one policy** in the same file. RLS
   without policies silently blocks everything; no RLS leaks everything.
   *(Enforced: audit_db.py fails otherwise.)*
6. **Destructive statements** (`DROP TABLE`, `TRUNCATE`, `DELETE` without `WHERE`)
   require a `-- DESTRUCTIVE: <reason>` comment in the file AND Richard's explicit
   approval before running anywhere. *(Enforced: audit_db.py fails without the comment.)*
7. **After any migration touching RLS policies**, run
   `scripts/tenant_isolation_test.sql` in the staging SQL editor — it raises an
   exception on any cross-kitchen leak. All three historical RLS incidents (db/53
   outage, db/55, db/62 lockout) belonged to exactly this class.
8. **Who runs migrations:** Richard, personally, via the Supabase SQL editor — staging
   first per rule 3. Claude writes files, never executes against production.

---

# Sautero — Database setup (Phase 1a)

Run these two files, in order, in the Supabase Dashboard → SQL Editor → New query:

1. `01_schema.sql` — creates all tables (kitchens, profiles, recipes, favorites,
   recipe_notes), enables row-level security, and sets up the auto-profile-on-signup trigger.
2. `02_migrate_recipes.sql` — creates one "My Kitchen" row and inserts all 173 recipes
   migrated from `Recipe_Book_v2.html`.

After running both, verify with:

```sql
select count(*) from recipes;   -- should return 173
select count(*) from kitchens;  -- should return 1
```

Fields that don't exist in the original recipe book yet (chef_notes, storage, shelf_life,
variations, scaling_notes, equipment, plating_suggestions, allergens, tags, cuisine, station,
image_url, cross_references, description) are intentionally NULL/empty after migration — they
get filled in later, through the app, per recipe.

`02_migrate_recipes.sql` is not safe to run twice without first clearing the `recipes` table
(it would duplicate all 173 rows) — it has no de-duplication logic, since it's meant as a
one-time initial import.

## Ingredients & pricing (added 2026-07-09)

3. `03_fix_signup_trigger.sql` / `04_lock_signup_function.sql` — fixes applied during Phase 1a
   testing (see ROADMAP.md), already run.
4. `05_ingredients_schema.sql` — creates the `ingredients` table (name, aliases, cuisine,
   category, unit, price, RLS).
5. `06_ingredients_seed.sql` — inserts a 535-item starter price list, generated from every
   ingredient found across the 173 recipes. **All prices are `estimated`** — reasoned from
   general Central European culinary/wholesale domain knowledge, not individually verified
   online (web search was rate-limited for the entire session this was generated in). Treat
   every price as a starting point, not a confirmed quote — editable anytime in the app's
   "Ingredients & Pricing" screen.

Verify with:
```sql
select count(*) from ingredients;  -- should return 535
```

## Storage type, seasons, and ingredient expansion (added 2026-07-10)

6. `30_ingredients_storage_season.sql` — adds `storage_type` and `seasons` columns to
   `ingredients` (both NULL/empty until filled below).
7. `31_ingredients_backfill_storage_season.sql` — fills `storage_type` and `seasons` for all 533
   existing ingredients, and splits the generic `'Produce'` category into `'Fruit'` / `'Vegetable'`.
8. `32_ingredients_expansion_new.sql` — adds ~730 new ingredients (Seafood as its own category,
   deeper Japanese/Asian pantry, nuts/seeds/legumes, cooking alcohol, Swiss/European AOP cheeses,
   condiments/sauces/ferments, baking/pâtisserie specifics, and species-level produce/meat/poultry/
   grains), bringing the total to roughly 1,263. **All prices, nutrition values, storage types and
   seasons are estimated** — same honest standard as `06_ingredients_seed.sql`. This is the
   demo/presentation-scoped ~1300-ingredient set, not the paused 20,000-row master database concept.

Verify with:
```sql
select count(*) from ingredients;  -- should return approximately 1263
```
