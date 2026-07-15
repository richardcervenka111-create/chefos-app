-- ChefOS -- Michelin-chef pass, batch 3: Plated Desserts, part 1 (2026-07-15/16).
--
-- Same treatment as batch 1 (db/64, Salads) and batch 2 (db/66, Dressings): fill in the blank
-- professional fields (chef_notes/storage/shelf_life/equipment/plating_suggestions), leave the
-- already-solid ingredients/method alone.
--
-- Plated Desserts is the biggest category (210 recipes) and was unblocked by Richard's 16.7.
-- decision to leave Asian-leaning recipes as-is rather than exclude/rewrite them -- so this pass
-- simply never touches them, same exclusion logic as batch 2's Yuzu Dressing/Nuoc Cham calls.
--
-- The first pull (created_by is null, category = 'Plated Desserts', chef_notes blank, ORDER BY
-- title, LIMIT 20) showed only 4 distinct dishes among those 20 rows, each appearing up to 6
-- times with a different id. Verified this is CORRECT, not a data bug: there are 6 kitchens, each
-- holding its own full 173-recipe ChefOS-shelf copy (seeded by db/87) -- 173 x 6 = 1038 total
-- created_by-null rows across the table, confirmed per-kitchen (each kitchen: 173 rows, 173
-- distinct dishes, zero internal duplication). Any query against `recipes` that doesn't scope by
-- kitchen_id will show every dish once per kitchen -- expected multi-tenant shape, not a dedup
-- problem. Consequence for this migration: one UPDATE per distinct dish, applied to every id in
-- that dish's 6-kitchen id set via `where id in (...)`, so all six kitchens' copies get the notes
-- in one statement rather than one line per row.
--
-- Excluded from this batch: "Baonut (Bao Doughnut)" -- the name itself references a bao bun shape
-- (Chinese steamed bun) and the recipe includes yuzu syrup as a named component. Genuinely
-- borderline the same way Yuzu Cauliflower was in the salads pass. Per Richard's 16.7. standing
-- instruction ("ak nevieš čo, tak to preskoč a iba to reportuj"), skipped rather than guessed --
-- still shows up in the category count as not-yet-done.
--
-- Professional-standard suggestions, not verified against this specific kitchen's exact
-- practice -- review before treating as gospel, same as any AI-generated content here.
--
-- TEST ON chefos-staging FIRST, same as every other migration.

-- Black Forest Mousse -- reads as a component base (scaled x1 -> x5 batch note), not a
-- standalone plate, so the notes below treat it that way rather than inventing a full build.
update recipes set
  equipment = 'Instant-read thermometer; immersion blender for a smooth emulsion; fine sieve for straining the anglaise',
  chef_notes = 'Bring the custard to no more than 82-84°C when tempering the yolks — past that it scrambles and the mousse never comes together smooth. Pour it over the chocolate while both are still hot and emulsify with an immersion blender for a glossy, stable base rather than folding by hand.',
  storage = 'Keeps refrigerated, covered, up to 2 days as a base component — bring back toward room temperature and re-emulsify briefly if it firms up before using.',
  shelf_life = '2 days refrigerated as a base component.',
  plating_suggestions = 'This is a base for a composed dessert, not a standalone plate — pipe or quenelle once set, and pair with the classic Black Forest notes (cherry, chocolate shavings) it is named for if they are not already part of the build.'
where id in ('bd8f0250-8838-40fb-a0d0-c27b44eae566','d590630b-e342-47be-b4e7-8a0eb5674352','4e04b9ea-1d04-45b1-a241-b2274c30148f','b174200b-fab5-4a71-af9d-ffdb325b754a','a2ff0f72-bcbe-4851-8a58-5fd1b6c9c88e','38757114-204b-47e6-9bd7-37670337133e');

-- Burnt Basque Cheesecake
update recipes set
  equipment = 'Springform tin, generously lined; stand mixer with paddle attachment',
  chef_notes = 'The dark, almost-burnt top and a pronounced wobble in the centre are the entire point of this style — resist pulling it earlier or baking it more evenly. Room-temperature cream cheese is what keeps the batter smooth; cold cream cheese leaves lumps no amount of beating fixes.',
  storage = 'Keeps refrigerated, well-wrapped, up to 4 days — the texture actually improves after a full day chilled.',
  shelf_life = '4 days refrigerated.',
  plating_suggestions = 'Serve at cool room temperature rather than fridge-cold for the creamiest texture; a clean slice needs a hot, dry knife wiped between cuts — the crustless, blistered sides are meant to look rustic and torn, not neat.'
where id in ('e0a22a07-8980-4b9d-8d79-47bbdc91dec1','7ef9aa2a-9ed0-45d0-9977-fc0448a285d9','631d8ad0-f0b8-4b36-a650-cb85c0c70fb5','5df45a16-adef-4dc8-be25-04037d8cbbb2','e7d49243-5c83-4839-b916-e78d0602e35e','f042beb3-6f16-44a9-af29-40d46187894a');

-- Cheesecake, Bergamot & Strawberries
update recipes set
  equipment = 'Springform tin or individual rings; water bath for baking; blender for the gel',
  chef_notes = 'Do not overbeat the filling once the eggs go in — excess air causes cracking as it bakes and sinking as it cools. The water bath is what keeps the edges from overcooking before the centre sets.',
  storage = 'Baked cheesecake keeps refrigerated up to 4 days. Bergamot gel keeps refrigerated, airtight, up to 5 days. Strawberry compote keeps refrigerated up to 3 days.',
  shelf_life = 'Cheesecake: 4 days refrigerated. Gel: 5 days refrigerated. Compote: 3 days refrigerated. Assemble the fresh strawberry slices just before serving — they weep once cut.',
  plating_suggestions = 'Dot or quenelle the bergamot gel rather than pooling it — its perfume is delicate and easily lost if overused; fresh strawberry slices and micro herbs go on last so they stay bright, not sitting in juices.'
where id in ('1ece8a68-db25-4812-8f09-355d2d05aef3','6ff9d942-e090-43fb-8c2f-31aa28b61db9');
