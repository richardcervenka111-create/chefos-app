-- Sautero — adds a free-text notes field to both task types in Mise en Place (the flat
-- checklist and the dish-grouped prep sheet), so a cook can leave a note for whoever
-- reads it next ("only 2 left, ordered more", "swapped for X today", etc).
alter table tasks add column if not exists notes text;
alter table prep_items add column if not exists notes text;
