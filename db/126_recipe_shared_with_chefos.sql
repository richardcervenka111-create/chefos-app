-- Sautero — "share this recipe with Sautero" (Richard, 17.7.): when saving a recipe, the app now
-- asks whether to contribute it to the Sautero library. Saying yes ALSO makes every AI helper
-- used on that recipe free (the claude-proxy skips the credit gate + metering for those calls).
--
-- The flag is just that — a flag. Shared recipes do NOT automatically appear on anyone's
-- Sautero shelf: Richard reviews contributions (select shared_with_chefos = true rows) and
-- promotes the good ones into the library deliberately. That keeps the library curated instead
-- of becoming a dumping ground, and means a bad-faith "share" grants nothing but free AI on
-- one recipe.

alter table recipes add column if not exists shared_with_chefos boolean not null default false;
grant select (shared_with_chefos) on recipes to authenticated;
