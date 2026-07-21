-- Sautero -- Check List projects (Richard, 16.7.): opening Check List now lands on a
-- Home-styled picker of "restaurant/project" tiles first, each one its own independent
-- instance of the exact same stations/prep-sheet system Check List already had. A kitchen can
-- hold multiple projects; picking (or creating) one is what used to just be "open Check List".
--
-- Also fixes a real leak while building this: DEFAULT_STATIONS/the "All stations" overview both
-- unconditionally offered SKY/Garde Manger/Lobby (sections from the hotel Richard prototyped
-- Sautero against) to every kitchen, empty, forever -- not real cross-kitchen data (RLS already
-- prevented that), but the STATION NAMES themselves leaking as available options to everyone.
-- Trimmed the app-side generic default down to what's actually common to any restaurant (Hot
-- Line, Entremetier, BQT, Desserts, Extra); Richard's original data (SKY included) is preserved
-- exactly as-is, just now living inside one project called "Development" instead of being the
-- kitchen's only Check List.
--
-- Schema: prep_items intentionally gets NO project_id of its own -- it's only ever reached via
-- dish_id, and dish_id already resolves through prep_dishes (which does carry project_id), so
-- item-level scoping falls out for free. tasks (the flat, non-dish-grouped list) and
-- prep_dishes both get project_id directly, same denormalized-by-design pattern "station"
-- already uses on both.
--
-- STAGING FIRST -- the backfill below writes project_id to every existing tasks/prep_dishes row
-- in every kitchen that has any.

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  name text not null,
  icon text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

alter table projects enable row level security;

create policy "read kitchen projects" on projects
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "create kitchen projects" on projects
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen projects" on projects
  for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));

alter table tasks add column if not exists project_id uuid references projects(id);
alter table prep_dishes add column if not exists project_id uuid references projects(id);

-- Backfill: every kitchen that has any existing tasks/prep_dishes rows gets ONE project named
-- "Development" holding all of it -- this is Richard's own kitchen in practice (the Schweizerhof
-- prototype data lives only there), but written generally so any kitchen with real pre-existing
-- Check List data is safely preserved under a project rather than silently orphaned. A kitchen
-- with zero existing rows gets no project at all -- it lands on the empty picker, exactly the
-- "ostatné účty nechaj prázdne" Richard asked for.
do $$
declare
  k record;
  new_project_id uuid;
begin
  for k in (
    select distinct kitchen_id from (
      select kitchen_id from tasks
      union
      select kitchen_id from prep_dishes
    ) x
  ) loop
    insert into projects (kitchen_id, name) values (k.kitchen_id, 'Development') returning id into new_project_id;
    update tasks set project_id = new_project_id where kitchen_id = k.kitchen_id and project_id is null;
    update prep_dishes set project_id = new_project_id where kitchen_id = k.kitchen_id and project_id is null;
  end loop;
end $$;
