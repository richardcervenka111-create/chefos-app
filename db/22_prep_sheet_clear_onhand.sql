-- ChefOS — ON HAND on the SKY prep sheet changed meaning: from the recipe's gram quantity
-- (seeded from the paper sheet) to a 0-13 stock count of how many are currently prepped and
-- ready. Clears the old gram values so the column starts blank for the new count-based use.
update prep_items
set on_hand = null
where dish_id in (select id from prep_dishes where station = 'SKY');
