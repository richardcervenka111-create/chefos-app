-- ChefOS — retiring Hotel Schweizerhof branding from recipe/dish names (2026-07-13).
--
-- Richard: the pilot kitchen is changing to Burrito Bandito & Lido, and the concrete thing that
-- needs to go is anything literally named/branded after the old employer — not the general
-- Schedule/Check-List structure or the other ~172 recipes, which he confirmed he didn't source
-- from them ("nič iné som od nich nepoužil").
--
-- Searched every SQL file in this project for "Schweizerhof" in an actual recipe/dish title
-- (not just a comment) and found exactly three: one recipe, two Check List dishes. This
-- RENAMES them (drops the "Schweizerhof " prefix) rather than deleting them outright — the
-- underlying dish (a brioche, a coq au vin blanc, a chocolate mousse) is a standard classic,
-- not the hotel's proprietary content; it's the naming that ties it to them. If you'd rather
-- these were deleted outright instead of just renamed, say so and a delete version is a
-- two-line change.

update recipes set title = 'Brioche'
where title = 'Schweizerhof Brioche' and kitchen_id = '11111111-1111-4111-8111-111111111111';

update prep_dishes set name = 'Coq au Vin Blanc'
where name = 'Schweizerhof Coq au Vin Blanc' and kitchen_id = '11111111-1111-4111-8111-111111111111';

update prep_dishes set name = 'Chocolate Mousse'
where name = 'Schweizerhof Chocolate Mousse' and kitchen_id = '11111111-1111-4111-8111-111111111111';

-- Belt-and-suspenders: catches the row if migration 29's DE→EN translation never actually ran
-- against your live DB and it's still sitting in German.
update prep_dishes set name = 'Chocolate Mousse'
where name = 'Schweizerhof Schokoladenmousse' and kitchen_id = '11111111-1111-4111-8111-111111111111';
