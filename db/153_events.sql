-- 153: Events tile (Richard, 18.7. — t172, reconfirmed as item 3 same day): banquets/functions
-- that are still upcoming. New Event manually, or Scan a photographed order/e-mail/contract and
-- AI reads the event type, client, headcount, menu and price (same vision pattern as Invoice
-- Scan / Custom Ingredients scan — record_event tool + claudeScanSourceBlock).
--
-- price stored EUR-based, same convention as every other price in the app (ingredients,
-- prep_dishes) — formatMoney() converts to the kitchen's display currency at render.
--
-- Safe straight to production — pure new table, RLS + policies included in the same file.

create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  title text not null,
  client text,
  headcount integer,
  menu text,
  price numeric,
  event_date date not null,
  event_time time,
  notes text,
  is_demo boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

alter table events enable row level security;

create policy "read kitchen events" on events
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "insert kitchen events" on events
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "update kitchen events" on events
  for update using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen events" on events
  for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
