-- 158: Consolidation Phase 2, step 2.1 (C2 EXPAND) — Zero Feature Loss protocol.
--
-- Adds kitchens.icons JSONB and backfills it from station_icons + recipe_category_icons:
--   { "stations": {"Hot Line":"🔥", ...}, "recipe_categories": {"Bakery":"🥖", ...} }
--
-- EXPAND ONLY: app/index.html is untouched in this step — it keeps reading/writing the two
-- old tables, which stay fully alive. Nothing user-visible can change. The app's kitchens
-- selects are all explicit column lists ('name' / 'display_currency, name'), so the new
-- column doesn't even enter any existing payload.
--
-- Known follow-up for step 2.2 (the read/write flip), noted now so it isn't forgotten:
--   · re-run this backfill UPDATE immediately before deploying the flip commit — icons
--     created between 2.1 and 2.2 land in the old tables and must be re-synced;
--   · kitchens UPDATE RLS is admin-only (db/48), but station_icons/recipe_category_icons
--     writes are open to every kitchen member — the flip therefore needs a SECURITY DEFINER
--     set_kitchen_icon() RPC (or a scoped policy) so non-admin members can still pick icons
--     when creating sections/categories. Zero Feature Loss: members' icon-picking must not
--     silently become admin-only.
--
-- STAGING FIRST (data-touching backfill UPDATE).

alter table kitchens add column if not exists icons jsonb not null default '{}'::jsonb;

update kitchens k set icons = jsonb_build_object(
  'stations', coalesce((
    select jsonb_object_agg(si.station, si.icon)
    from station_icons si where si.kitchen_id = k.id
  ), '{}'::jsonb),
  'recipe_categories', coalesce((
    select jsonb_object_agg(ri.category, ri.icon)
    from recipe_category_icons ri where ri.kitchen_id = k.id
  ), '{}'::jsonb)
);
