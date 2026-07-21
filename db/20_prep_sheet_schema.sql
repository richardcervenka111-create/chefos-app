-- Sautero — Prep Sheet: a dish-grouped view inside Mise en Place, matching Richard's real
-- paper prep sheet (dish header with price, then its component items underneath). Built
-- generally so any station can use this style later, not just SKY.
create table if not exists prep_dishes (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  station text not null,          -- e.g. 'SKY'
  name text not null,
  price numeric,
  sort_order int not null default 0,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists prep_items (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  dish_id uuid not null references prep_dishes(id) on delete cascade,
  name text not null,
  on_hand text,                    -- amount, e.g. "150g", "0.5 Stk" (renamed from "amount" on the paper sheet)
  priority smallint not null default 3 check (priority between 1 and 5),  -- 1 = critical, 5 = can wait
  prep_time text,                  -- e.g. "10 min" — pulled from a shared reference over time
  sort_order int not null default 0,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table prep_dishes enable row level security;
alter table prep_items enable row level security;

create policy "read kitchen prep dishes" on prep_dishes for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen prep dishes" on prep_dishes for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen prep dishes" on prep_dishes for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen prep dishes" on prep_dishes for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));

create policy "read kitchen prep items" on prep_items for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen prep items" on prep_items for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen prep items" on prep_items for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen prep items" on prep_items for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
