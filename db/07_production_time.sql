-- ChefOS — adds an editable "production time" to each recipe.
-- This is separate from the existing active/passive method-time estimates (which are
-- guessed from the written steps) — production time is something the chef sets directly,
-- and will later be used by the Mise en Place / prep-list feature to plan a station's day.
alter table recipes add column if not exists production_time text;
