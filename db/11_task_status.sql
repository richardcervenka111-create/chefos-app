-- Sautero — replaces the simple done/not-done checkbox on tasks with a 3-state status:
-- TO DO -> CHECK -> FINISH. "CHECK" is for a task that's done but wants someone (e.g. the
-- chef) to verify it before it counts as truly finished.
alter table tasks add column if not exists status text not null default 'todo'
  check (status in ('todo','check','finish'));

update tasks set status = case when done then 'finish' else 'todo' end;
