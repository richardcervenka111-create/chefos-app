-- Sautero — adds a status field to prep items (SKY prep sheet etc.), same TO DO / CHECK /
-- FINISH pattern as the regular Mise en Place task list, plus a 4th option DONT DO for items
-- that don't need prepping today. This lives separately from priority (which stays 1-5).
alter table prep_items add column if not exists status text not null default 'todo'
  check (status in ('todo','check','finish','dontdo'));
