-- Sautero — adds origin, season, and substitution info to each ingredient.
alter table ingredients add column if not exists origin text;
alter table ingredients add column if not exists season text;
alter table ingredients add column if not exists substitutes text;
