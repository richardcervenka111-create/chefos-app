-- Sautero — ingredient price verification, batch 1 (daily ingredient agent, 2026-07-14)
--
-- Context: db/06_ingredients_seed.sql explicitly flagged that all 535 starter prices were
-- ESTIMATES, never checked against a real source (web search was rate-limited at the time).
-- This batch verifies 16 of the highest-usage staple items (used across many recipes) against
-- real, current Swiss retail prices via Migros/Migipedia product pages (and one Expatistan
-- cost-of-living figure for milk, where no single clean Migipedia price was found).
--
-- Method: took the standard/mid-tier retail option (not the cheapest budget line, not a
-- premium/bio line) as the reference price, same spirit as the original estimate. Converted
-- CHF -> EUR @ 1.06, the same fixed rate already used in db/46 and db/58 (kept consistent
-- across the codebase, not a live FX rate).
--
-- Caveat: these are Swiss RETAIL supermarket prices (Migros), not foodservice/wholesale
-- pricing. For a handful of items (Parmesan, Dijon Mustard, Soy Sauce, Honey) that pushed the
-- price notably higher than the original estimate, retail small-pack pricing is genuinely more
-- expensive per kg than a catering-size wholesale pack would be — flagged in each row's notes.
-- Chefs should still sanity-check against their own supplier invoices where those differ a lot.
--
-- price_updated_at is set to now() for every row here, per the convention in
-- db/05_ingredients_schema.sql: NULL means "never confirmed", a timestamp means "someone
-- checked this against a real source".
--
-- STAGED FOR REVIEW — not run against production. Richard runs migrations himself.

update ingredients set price = 1.91, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros M-Classic Granulated Sugar, CHF 1.80/kg -> EUR (@1.06). Source: Migipedia product page. Was an unverified estimate (0.90 EUR) since db/06.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Sugar');

update ingredients set price = 1.91, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros JuraSel Tafelsalz mit Jod, CHF 0.90/500g = 1.80 CHF/kg -> EUR (@1.06). Source: Migipedia product page. Was an unverified estimate (0.60 EUR) since db/06.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Salt');

update ingredients set price = 16.75, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros "Die Butter" standard block, CHF 3.95/250g = 15.80 CHF/kg -> EUR (@1.06). Source: Migipedia product page. Retail price, notably above the old 7.20 EUR/kg estimate — foodservice bulk butter is typically cheaper per kg, sanity-check vs. your supplier.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Butter');

update ingredients set price = 1.94, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: average whole-fat milk price in Zurich, CHF 1.83/l -> EUR (@1.06). Source: Expatistan cost-of-living data (no single clean Migipedia unit price found). Was an unverified estimate (1.10 EUR) since db/06.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Milk');

update ingredients set price = 10.55, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros Don Pablo Olive Oil Extra Virgin 1L, CHF 9.95/l -> EUR (@1.06). Source: Migipedia product page. Was an unverified estimate (6.50 EUR) since db/06.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Olive Oil');

update ingredients set price = 1.48, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros Fresca Onions, CHF 1.40/kg -> EUR (@1.06). Source: Migipedia product page. Was an unverified estimate (0.80 EUR) since db/06.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Onion');

update ingredients set price = 1.59, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros Fresca Carrots, CHF 1.50/kg -> EUR (@1.06). Source: Migipedia product page. Was an unverified estimate (0.70 EUR) since db/06.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Carrot');

update ingredients set price = 3.71, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros Celery (standard, non-bio), CHF 3.50/kg -> EUR (@1.06). Source: Migipedia product page. Was an unverified estimate (1.80 EUR) since db/06.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Celery');

update ingredients set price = 38.16, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros Sélection Parmesan, CHF 7.20/200g = 36.00 CHF/kg -> EUR (@1.06). Source: Migipedia product page. Retail block price, notably above the old 16.00 EUR/kg estimate — a catering-size wheel/wedge from a cheese wholesaler will run cheaper per kg.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Parmesan');

update ingredients set price = 0.79, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros IP-SUISSE Aus der Region Picnic Eggs 53+, CHF 4.45/6 = 0.7417 CHF/egg -> EUR (@1.06). Source: Migipedia product page. Was an unverified estimate (0.30 EUR) since db/06.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Egg');

update ingredients set price = 1.06, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros M-Budget All-purpose flour, CHF 1.00/kg -> EUR (@1.06). Source: Migipedia product page. Close to the old 0.90 EUR estimate, small upward correction.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Plain Flour');

update ingredients set price = 1.06, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros M-Budget All-purpose flour, CHF 1.00/kg -> EUR (@1.06). Source: Migipedia product page. Same reference as Plain Flour (this is the generic dredging-flour entry). Was an unverified estimate (0.90 EUR) since db/06.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Flour');

update ingredients set price = 7.21, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros Valflora Double Cream 35% UHT, CHF 3.40/500ml = 6.80 CHF/l -> EUR (@1.06). Source: Migipedia product page. Was an unverified estimate (3.20 EUR) since db/06.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Cream');

update ingredients set price = 18.02, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros M-Classic Acacia honey (budget line), CHF 8.50/500g = 17.00 CHF/kg -> EUR (@1.06). Source: Migipedia product page. Retail price, above the old 8.50 EUR/kg estimate; regional/premium honey runs 23-38 CHF/kg retail, this is the cheapest real option found.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Honey');

update ingredients set price = 10.44, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros Kikkoman Soya Sauce 1L, CHF 9.85/l -> EUR (@1.06). Source: Migipedia product page. Retail branded price, notably above the old 3.80 EUR estimate — a catering-size soy sauce (5L+ jug) is typically cheaper per litre.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Soy Sauce');

update ingredients set price = 24.38, price_currency = 'EUR', price_updated_at = now(),
  notes = 'Verified 2026-07-14: Migros Thomy Dijon Mustard, CHF 2.30/100g = 23.00 CHF/kg -> EUR (@1.06). Source: Migipedia product page. Small-jar retail price, well above the old 6.50 EUR/kg estimate — a catering-size tub is much cheaper per kg; treat this as an upper bound, not a bulk-buy price.'
  where kitchen_id = '11111111-1111-4111-8111-111111111111' and lower(name) = lower('Dijon Mustard');
