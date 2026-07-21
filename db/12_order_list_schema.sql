-- Sautero — Order List: per-station checklist of ingredients to order, with quantity + unit.
-- A row existing here means "this ingredient is currently on this station's order list" —
-- unchecking an item in the app deletes its row rather than flagging it inactive.
create table if not exists order_list_items (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  station text not null,
  ingredient_id uuid not null references ingredients(id) on delete cascade,
  quantity numeric,
  unit text not null check (unit in ('kg','l','pc')),
  created_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  unique (kitchen_id, station, ingredient_id)
);

alter table order_list_items enable row level security;

create policy "read kitchen order list" on order_list_items
  for select using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "write kitchen order list" on order_list_items
  for insert with check (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "update kitchen order list" on order_list_items
  for update using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
create policy "delete kitchen order list" on order_list_items
  for delete using (
    kitchen_id in (select kitchen_id from profiles where id = auth.uid())
  );
