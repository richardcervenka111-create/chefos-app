-- Sautero — supplier field on ingredients (Richard, 17.7.): who this item is bought from. Filled
-- by Invoice Scan (it reads the vendor from the invoice header and stamps it on every line from
-- that invoice) and editable by hand. Groundwork for one-tap ordering per supplier later.
alter table ingredients add column if not exists supplier text;
