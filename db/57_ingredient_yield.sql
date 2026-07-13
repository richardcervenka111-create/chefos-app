-- ChefOS — yield/waste factor for ingredients (backlog t27, 2026-07-13).
-- Professional food cost accounts for trim loss (peeled veg, filleted fish, boned meat) — the
-- price on an ingredient is for the raw product as bought, but a recipe line is written in
-- usable/prepped quantity. Without a yield factor, cost is systematically underestimated,
-- and the chefs this is being sold to notice that first. 100 = no loss (default, matches every
-- existing row's real behavior today). e.g. 80 means 20% is trim/waste, so the effective cost
-- per usable unit is price / 0.80.
alter table ingredients add column if not exists yield_pct numeric not null default 100
  check (yield_pct > 0 and yield_pct <= 100);
