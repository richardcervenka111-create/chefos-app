-- Sautero -- Michelin-chef pass, batch 4: Plated Desserts, part 2 (2026-07-15/16).
--
-- Continuation of db/91 (batch 3, part 1) -- same treatment, same 6-kitchen id-set pattern per
-- distinct dish (see db/91's header for why every dish needs 6 ids, not 1).
--
-- Excluded from this batch: "Green Tea Ice Cream" and "Green Tea Popcorn" -- green tea (matcha)
-- is the defining flavour of both, the same class of call as excluding Yuzu Dressing in batch 2
-- (db/66). Skipped rather than guessed, per Richard's 16.7. standing instruction. "Illanka
-- Crémeux" was NOT excluded -- Illanka is a Peruvian-origin dark chocolate couverture (a Cacao
-- Barry product name), not an Asian ingredient or technique.
--
-- Professional-standard suggestions, not verified against this specific kitchen's exact
-- practice -- review before treating as gospel, same as any AI-generated content here.
--
-- TEST ON chefos-staging FIRST, same as every other migration.

-- Chocolate Cookie House
update recipes set
  equipment = 'Rolling pin; sharp templates or a craft knife for clean panel cuts; piping bag for assembly (royal icing or melted chocolate as the "glue")',
  chef_notes = 'Chill the dough fully before rolling and cutting — warm dough loses sharp edges and the panels won''t sit flush once assembled. Bake panels slightly longer than a normal cookie so they''re sturdy enough to bear weight in the finished structure.',
  storage = 'Unbaked dough keeps refrigerated, wrapped, up to 3 days, or frozen up to 1 month. Baked, unassembled panels keep airtight at room temperature up to 1 week.',
  shelf_life = 'Dough: 3 days refrigerated / 1 month frozen. Baked panels: 1 week airtight, room temperature. Assembled piece: best within 2-3 days before the "glue" softens.',
  plating_suggestions = 'Assemble directly on the final serving base or cake board — moving a fully built structure afterward risks cracking the joins.'
where id in ('a5baff10-fcbd-4a87-9b9d-498d1fe609e3','fde68a9d-943d-4894-98ec-4f542b0b95db','f947a55e-b7f8-4c9d-a888-dfe33fc70630','bb943914-52e5-4da4-8a9f-3e61c40c2965','73ebc3ff-3d40-4c25-8a4d-95e0feee3b53','216dd8b6-f92d-4793-b60f-068796cc12ee');

-- Chocolate Financier
update recipes set
  equipment = 'Financier moulds; fine sieve for the dry ingredients; small pot for browning the butter',
  chef_notes = 'Watch the butter closely once it starts to brown — it goes from nutty to burnt in seconds, and that bitterness carries straight into the batter. Fold rather than beat once the egg whites go in, to keep the crumb light rather than dense.',
  storage = 'Baked financiers keep airtight at room temperature up to 3 days, or frozen up to 1 month. Unbaked batter keeps refrigerated up to 2 days.',
  shelf_life = 'Baked: 3 days room temperature / 1 month frozen. Batter: 2 days refrigerated.',
  plating_suggestions = 'Serve slightly warm if possible — the crust stays crisp and the centre stays moist; a dusting of cocoa or a single quenelle alongside is enough, the financier itself is the focus.'
where id in ('9bd419d6-a185-4223-bb3a-937534ef1181','21ebcaae-8ed4-4bf7-b6e2-af3a4c92c751','8bda03d6-9416-4beb-a596-c1061786db80','69657f8f-a855-43d5-8b17-195a140feea9','d0fd5eb3-efde-418a-ac0a-1bd4686899a4','e5ac4a59-5c3c-4044-9c6a-fddb10372cf0');

-- Chocolate Tuile
update recipes set
  equipment = 'Silicone baking mat or template stencil; offset spatula for spreading; a rolling pin or curved mould to shape while warm',
  chef_notes = 'Tuiles set within seconds of leaving the oven — have your shaping mould or rolling pin ready before they finish baking, or you''ll be left with a flat, unusable disc.',
  storage = 'Keeps airtight at room temperature with a desiccant packet or silica gel up to 3-4 days — humidity is the enemy, it goes soft and loses snap.',
  shelf_life = '3-4 days airtight at room temperature, away from moisture.',
  plating_suggestions = 'Place tuiles at the very last moment before service — even brief contact with a moist component (ice cream, mousse) will soften them.'
where id in ('84d4112a-ff35-4512-bcd9-ef65bfda3817','a5b31118-4d75-486e-a6da-3422be72b87a','80c627b2-74a5-4eae-82da-bd58e36ed6ff','7d724f53-f5f7-405a-b50a-1de973c793b9','42fb179f-f03a-4a3d-946b-38c3964e97e2','62513ca8-9dd7-4d94-938d-9ef7a7727b21');

-- Classic Vanilla Crème Brûlée
update recipes set
  equipment = 'Ramekins; kitchen blowtorch; fine strainer; water bath',
  chef_notes = 'Strain the custard before pouring and skim the foam off the top — either left in shows up as an uneven, pitted brûlée surface. Torch a thin, even layer of sugar rather than a thick one; too much sugar burns on the outside before it fully caramelizes through.',
  storage = 'Baked, unsugared custards keep refrigerated, covered, up to 3 days — brûlée the sugar only immediately before serving, it softens and weeps within 15-20 minutes once torched.',
  shelf_life = 'Custard: 3 days refrigerated. Brûléed top: serve within 15-20 minutes of torching.',
  plating_suggestions = 'Serve in the baking ramekin, still faintly warm on top from the torch against the cold set custard beneath — the contrast is the point.'
where id in ('fb49992e-a471-44fc-8d8a-68ace0f2ed71','afe0c7fc-1528-4bd5-87e4-d79eaba0d0c3','aeb16b28-68bd-45b6-bfdf-94188a56c787','cbc5c63b-89dc-4cae-a583-e10158ba0a32','1e18bd8e-da32-498c-8a8f-1f583d262562','20cad100-61bf-47ae-ad95-f481af7d3db1');

-- Coconut Marshmallow
update recipes set
  equipment = 'Stand mixer with whisk attachment; sugar thermometer; piping bag or lined tray for setting',
  chef_notes = 'Get the syrup to a true 115°C before adding it to the gelatine — under that, the marshmallow won''t hold structure and stays sticky instead of setting.',
  storage = 'Keeps airtight at room temperature, dusted with cornstarch or icing sugar to stop sticking, up to 1 week.',
  shelf_life = '1 week at room temperature, airtight.',
  plating_suggestions = 'Torch lightly just before serving for a toasted note and a glossy finish, if the dish calls for it — otherwise keep it clean-cut and pale for contrast against darker elements.'
where id in ('2ee3b7d3-d10e-4f26-978d-5f64677b0ca3','6b652ffa-caf0-4bb8-a830-a1a2a46f7cf5','28b5352e-3a14-4ba4-b41f-12147057f7f6','2f11c424-b33f-4dbd-9ff0-93717103b307','3a11550f-57fe-499a-bf09-aacbb895be22','2e4cec0e-87f8-4df1-ae9d-26d68af89faf');

-- Frozen Nougat (nougat glacé)
update recipes set
  equipment = 'Stand mixer with whisk attachment; sugar thermometer; terrine mould or individual moulds; freezer space to set fully flat',
  chef_notes = 'Cook the sugar syrup to a true 120°C before streaming it into the egg whites — this is what pasteurizes them and builds the meringue''s structure, so don''t rush or guess the temperature. Fold in the cream and praline gently once the meringue has cooled, or you''ll knock out the air that keeps this frozen rather than icy.',
  storage = 'Keeps frozen, well-wrapped, up to 1 month.',
  shelf_life = '1 month frozen.',
  plating_suggestions = 'Slice straight from the freezer with a hot, dry knife for clean edges — it softens fast at room temperature, so plate close to service.'
where id in ('40d6d501-cb48-4c87-8402-b5bec78a3f9a','c8baf1a3-deb9-4e79-a574-f2324128b8ec','1b9bad6f-8686-40ad-9a40-79dbe1fe2b52','4e0ac31a-0cfa-4d0a-a564-323ccce7e773','1dc4f375-e611-4d1b-a57e-72a1063065f5','30b3faaf-87e7-4dcb-8369-164dbd81f433');

-- Ganache — Mango-Passion
update recipes set
  equipment = 'Fine sieve for the purées; hand blender for emulsifying',
  chef_notes = 'Blend well past the point it looks smooth — a proper emulsion takes longer than it seems like it should, and an under-blended ganache splits once piped or spread. The 1-2 day age rest genuinely firms the texture and settles the flavour; don''t skip it if the schedule allows.',
  storage = 'Keeps refrigerated, airtight, up to 5 days once emulsified.',
  shelf_life = '5 days refrigerated.',
  plating_suggestions = 'Use once fully set and cool — piped or spread while still warm loses its shape and won''t hold clean lines.'
where id in ('8f8d3dce-8688-4808-8a05-cad9a218b757','3a0e8ccd-8769-4a93-80b9-bb34d46183f8','6aac558a-d575-4da4-b52e-a2f16b5fda45','3ae522a8-490c-479a-b038-7bdf8f2560f1','d15ac481-ee91-4604-b532-12dd930bec82','980dc172-8ef7-44d6-8831-2c09ee7a1018');

-- Ganache — Raspberry
update recipes set
  equipment = 'Fine sieve for the purée; hand blender for emulsifying',
  chef_notes = 'Same rule as any fruit ganache: blend past the point it looks done for a true emulsion, and let it age 1-2 days refrigerated before using — it firms up and the flavour rounds out.',
  storage = 'Keeps refrigerated, airtight, up to 5 days once emulsified.',
  shelf_life = '5 days refrigerated.',
  plating_suggestions = 'Use once fully set and cool — piped or spread while still warm loses its shape and won''t hold clean lines.'
where id in ('41234ef3-b552-4649-9d23-34e9d783ecba','e2df0c55-6e2e-4720-92f6-6db3ff7530b9','1dfe6257-588a-4656-9586-b1432df5aba8','01acd71a-27d6-4a69-ad48-e0243e31c8c4','a6d01da4-0116-4e8a-8142-8b385e35ef98','f258ae47-f125-4f1e-8cc9-6ff8dd62c4e6');

-- Ganache — Vanilla
update recipes set
  equipment = 'Fine strainer for the infused cream; hand blender for emulsifying',
  chef_notes = 'Let the vanilla infuse in the hot cream a few extra minutes off the heat before straining — rushing this is the most common reason this ganache tastes flat. Blend well past the point it looks smooth for a stable emulsion.',
  storage = 'Keeps refrigerated, airtight, up to 5 days once emulsified.',
  shelf_life = '5 days refrigerated.',
  plating_suggestions = 'Use once fully set and cool — piped or spread while still warm loses its shape and won''t hold clean lines.'
where id in ('6d847f35-6813-4433-8b36-41ff6a8e27fd','90c8d1b8-292e-4109-b1d1-d8b66e3c9759','7884c42b-31b1-43c0-a1c6-54c4733103d4','26c62967-ef44-4df6-811d-a6fb13ec7436','49581303-9a33-437a-89f9-7a10e85974af','20187291-dd5e-4fab-b380-b1d789da560f');

-- Glaze (1) — White Chocolate/Cocoa Butter
update recipes set
  equipment = 'Double boiler or microwave for gentle melting; hand blender for a smooth finish',
  chef_notes = 'Keep the heat gentle — white chocolate scorches and seizes easily if it gets too hot too fast. This is a simple base glaze; colour or flavour it while still warm and fluid if the dish calls for it.',
  storage = 'Keeps at room temperature, airtight, for several weeks — reheat gently to re-liquefy before use.',
  shelf_life = 'Several weeks at room temperature, airtight.',
  plating_suggestions = 'Glaze at pouring consistency (around 30-35°C) over a fully frozen or well-chilled item for the cleanest, most even coat.'
where id in ('f4834b0c-3a01-4ef3-ac18-3531d286cf1b','04f3afe9-3dd5-4e29-bdc3-1a221f00d5a6','a019061d-d286-4539-9a10-9f19dcef51f1','8cc07d4e-2e16-4a29-a65e-e11d4a01bfd6','74699a33-ed2f-4f59-8289-7c2a61dd54df','2737d9e0-6f92-4cf4-aa9f-13b366b6ba5e');

-- Glaze (2) (pear mirror glaze)
update recipes set
  equipment = 'Sugar thermometer; hand blender; fine sieve to strain before use',
  chef_notes = 'Strain the finished glaze through a fine sieve to remove air bubbles before using — bubbles show up as dull spots on the final mirror finish. Use at around 30-35°C over a frozen item for the classic glass-smooth coat.',
  storage = 'Keeps refrigerated, airtight, up to 1 week — gently rewarm and re-strain before use.',
  shelf_life = '1 week refrigerated.',
  plating_suggestions = 'Pour in one continuous motion over a fully frozen piece set on a rack, letting the excess drop away cleanly rather than trying to smooth it by hand.'
where id in ('b6eed336-201a-4b6c-b9a8-9ad7a9068ceb','57937ee7-3f32-49b8-8266-cabfd15c005b','6130d2b2-80a4-4c9d-9b76-aab9e35f0077','8ccfcdc9-fb60-42f7-9de3-c6e3d76f127c','ab0d5d4d-7ec3-47c1-be33-cf101afaf7d0','76a0c650-b4ac-4734-a72c-cd19ed91a196');

-- Illanka Crémeux (Illanka = a Cacao Barry couverture, not an Asian ingredient)
update recipes set
  equipment = 'Instant-read thermometer; hand blender for emulsifying; fine sieve for straining the anglaise',
  chef_notes = 'Same anglaise-then-emulsify technique as any crémeux base — temper the yolks gently (no more than 82-84°C) and pour hot over the chocolate to melt and bind it into a glossy, stable crémeux.',
  storage = 'Keeps refrigerated, covered, up to 3 days.',
  shelf_life = '3 days refrigerated.',
  plating_suggestions = 'Pipe once set and chilled for a clean quenelle or dot — it loosens if worked too long at room temperature, so pipe cold and serve promptly.'
where id in ('907e50a8-ce51-4f58-87b4-bc85924fa904','8b23bf27-aa00-4087-bdc0-c832f6a546f2','344c3928-6430-4817-943d-eb4f9f8daf70','7571119a-4cbf-4350-945a-a94cd4a18753','e1390656-8c4e-434f-a001-e5cace26d8b4','9ffda893-414a-4b6a-8f03-de68a6d3e9c7');
