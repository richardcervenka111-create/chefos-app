-- Sautero — adds standard nutrition-label values (per 100g/100ml) to each ingredient.
-- The app computes a recipe's total nutrition from these the same way it already computes
-- recipe cost from ingredient prices — matching ingredient lines by name, converting units,
-- and summing.
alter table ingredients add column if not exists kcal_per_100g numeric;
alter table ingredients add column if not exists protein_g_per_100g numeric;
alter table ingredients add column if not exists carbs_g_per_100g numeric;
alter table ingredients add column if not exists fat_g_per_100g numeric;
