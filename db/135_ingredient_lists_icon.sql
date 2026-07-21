-- Sautero — colored-book icon for custom ingredient lists (Richard, 17.7.), same as recipe
-- projects got in db/123. Lets a new ingredient list pick from the 8 colored books instead of a
-- fixed clipboard. Fixed shelves (Sautero, My Ingredients) keep their built-in icons in the app.
alter table ingredient_lists add column if not exists icon text not null default '📋';
