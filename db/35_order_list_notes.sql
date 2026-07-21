-- Sautero — Order List gets a free-text note per item (e.g. "ask for the smaller crates"),
-- needed for the new quick "🛒 Add to Order List" button on Check List items and recipe
-- ingredient rows.
alter table order_list_items add column if not exists notes text;
