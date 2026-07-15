-- ChefOS — HACCP wave 2 (15.7.): Label Expiry tracking.
--
-- Until now the app never remembered what labels were printed — printing was just
-- window.print() and the queue lived only in localStorage. This table records every printed
-- label (one row per queue entry, with qty) together with its computed use-by date, so the
-- new HACCP > Label Expiry screen can show what's in the kitchen right now and what's near
-- or past its date. A row is deleted when the kitchen marks the item used/discarded.
--
-- Fryer Oil and Pest Control (the other two wave-2 tiles) need NO new schema — db/77's check
-- constraints already listed type='fryer_oil' (haccp_measurement_log) and
-- category='pest_control' (haccp_checklist_items) ahead of time, exactly for this wave.
--
-- Pure new table, no changes to existing data — safe to run directly on production
-- (same class as db/77).

create table if not exists print_label_log (
  id uuid primary key default gen_random_uuid(),
  kitchen_id uuid not null references kitchens(id),
  name text not null,
  qty integer not null default 1,
  station text,
  use_by date,          -- null when the product has no shelf life set in print_label_settings
  printed_by uuid references auth.users(id),
  printed_at timestamptz not null default now()
);

alter table print_label_log enable row level security;

create policy "read kitchen print label log" on print_label_log
  for select using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "write kitchen print label log" on print_label_log
  for insert with check (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
create policy "delete kitchen print label log" on print_label_log
  for delete using (kitchen_id in (select kitchen_id from profiles where id = auth.uid()));
