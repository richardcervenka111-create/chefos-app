-- Sautero — Check List audit log (2026-07-13).
-- Backlog v2 (Solution Architect + PM): the MVP promise is "everyone sees what's done
-- and what's not, without a single conversation about whose fault it is" — but until now
-- nothing recorded WHO changed an item, only its current state. This adds a lightweight
-- append-only trail: every status/on-hand/priority/notes change on a prep_item gets one row
-- here, visible to the whole kitchen (not admin-only — the point is shared visibility, same
-- as the checklist itself).
create table if not exists check_list_audit_log (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid references kitchens(id),
  item_id uuid references prep_items(id) on delete cascade,
  item_name text not null,
  dish_name text,
  station text,
  field text not null,
  old_value text,
  new_value text,
  changed_by uuid references auth.users(id),
  changed_by_name text,
  created_at timestamptz not null default now()
);
create index if not exists check_list_audit_log_item_idx on check_list_audit_log(item_id, created_at desc);

alter table check_list_audit_log enable row level security;

create policy "kitchen members read audit log" on check_list_audit_log
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );

create policy "kitchen members write audit log" on check_list_audit_log
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
