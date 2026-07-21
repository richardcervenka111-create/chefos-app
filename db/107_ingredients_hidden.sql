-- Sautero — ingredients get a `hidden` flag (Richard, 16.7., bod 1) — same soft-hide convention
-- prep_dishes already uses (db/78-era), needed for the new long-press context menu (Hide/
-- Unhide) on ingredient rows. Personal ingredients can be hidden by their owner; shared ones by
-- anyone who could already edit them (kitchen-wide write access, or an admin — matches db/105).
alter table ingredients add column if not exists hidden boolean not null default false;
grant select (hidden) on ingredients to authenticated;
