-- ChefOS — pick an icon for a recipe project (Richard, 16.7. neskoro večer): 8 colored books to
-- choose from when creating a new project, instead of always the same 🗂️.
alter table recipe_lists add column if not exists icon text not null default '🗂️';
