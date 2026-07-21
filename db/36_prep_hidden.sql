-- Sautero — hide (not delete) a Check List item, dish, or whole section. Hidden rows stay in
-- the database (unlike delete) and can be brought back via a "Show hidden" toggle in the app.
alter table prep_dishes add column if not exists hidden boolean not null default false;
alter table prep_items add column if not exists hidden boolean not null default false;
