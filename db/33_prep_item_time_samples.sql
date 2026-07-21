-- Sautero — lets anyone add a real time observation to a prep item, whenever they want, instead
-- of only ever seeing the original placeholder estimate. A submitted time doesn't overwrite the
-- stored minute value outright — it's averaged in, tracked via a sample count per stage, so the
-- number gets more accurate the more people log it. Count 0 means "still the seeded placeholder,
-- no real observation yet" — the first real submission replaces it outright (count 0 -> 1)
-- rather than averaging a real number against a random guess; every submission after that
-- properly averages against the running count.
alter table prep_items add column if not exists todo_minutes_n int not null default 0;
alter table prep_items add column if not exists check_minutes_n int not null default 0;
alter table prep_items add column if not exists finish_minutes_n int not null default 0;
