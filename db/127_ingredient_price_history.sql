-- Sautero — ingredient price history (Richard, 17.7.): every price set by the new Invoice Scan
-- (and manual price edits) is logged as an append-only row, so Kitchen Reports can show HOW
-- prices move over time and project a trend — something the live `ingredients.price` column
-- alone can never answer (it only knows the latest number).

create table if not exists ingredient_price_history (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  ingredient_id uuid references ingredients(id) on delete cascade,
  name text not null,               -- denormalised, so history survives renames readably
  price numeric not null,           -- stored in EUR, same convention as ingredients.price
  unit text,
  source text not null default 'invoice_scan',  -- 'invoice_scan' | 'manual'
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create index if not exists ingredient_price_history_kitchen_idx
  on ingredient_price_history(kitchen_id, created_at);

alter table ingredient_price_history enable row level security;

create policy "read kitchen price history" on ingredient_price_history
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen price history" on ingredient_price_history
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
