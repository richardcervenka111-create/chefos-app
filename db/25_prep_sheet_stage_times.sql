-- ChefOS — replaces the free-text 'Time to prep' with three per-status minute values
-- per ingredient: how long TO DO / CHECK / FINISH each take (Richard's example: Kopfsalatherz
-- = 8 / 1 / 3 min — TO DO is the full prep, CHECK is a quick recheck, FINISH is the last
-- touch). Whichever status an item is on right now, that item's matching minute value is
-- what counts toward the running total. Values here are random placeholders (TO DO 5-18min
-- per Richard's instruction, CHECK/FINISH scaled smaller) — NOT real timings, adjust in app.

alter table prep_items add column if not exists todo_minutes int;
alter table prep_items add column if not exists check_minutes int;
alter table prep_items add column if not exists finish_minutes int;

do $$
declare
  v_dish_id uuid;
begin
  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Kopfsalat';
  update prep_items set todo_minutes = 10, check_minutes = 1, finish_minutes = 3 where dish_id = v_dish_id and name = 'Kopfsalatherz';
  update prep_items set todo_minutes = 15, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Wildkräuter';
  update prep_items set todo_minutes = 18, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Croutons';
  update prep_items set todo_minutes = 10, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Radieschen';
  update prep_items set todo_minutes = 13, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Dijon Vinaigrette';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Burrata';
  update prep_items set todo_minutes = 6, check_minutes = 2, finish_minutes = 4 where dish_id = v_dish_id and name = 'Mini Burrata';
  update prep_items set todo_minutes = 6, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Inka Tomaten';
  update prep_items set todo_minutes = 13, check_minutes = 2, finish_minutes = 3 where dish_id = v_dish_id and name = 'Olivenöl';
  update prep_items set todo_minutes = 18, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Weisser Balsamico';
  update prep_items set todo_minutes = 8, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Gegrillter Pfirsich';
  update prep_items set todo_minutes = 14, check_minutes = 3, finish_minutes = 5 where dish_id = v_dish_id and name = 'Kräutersalat';
  update prep_items set todo_minutes = 5, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Gewürzhonig';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Sellerie-Apfel Salat';
  update prep_items set todo_minutes = 13, check_minutes = 1, finish_minutes = 4 where dish_id = v_dish_id and name = 'Castelfranco & Tardivo';
  update prep_items set todo_minutes = 11, check_minutes = 1, finish_minutes = 4 where dish_id = v_dish_id and name = 'Stangensellerie';
  update prep_items set todo_minutes = 6, check_minutes = 3, finish_minutes = 5 where dish_id = v_dish_id and name = 'Granny Smith';
  update prep_items set todo_minutes = 13, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Baumnüsse';
  update prep_items set todo_minutes = 6, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Roquefort Dressing';
  update prep_items set todo_minutes = 10, check_minutes = 1, finish_minutes = 4 where dish_id = v_dish_id and name = 'Kräutersalat';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Mini Lattich Caesar';
  update prep_items set todo_minutes = 16, check_minutes = 1, finish_minutes = 6 where dish_id = v_dish_id and name = 'Mini Lattich Blätter';
  update prep_items set todo_minutes = 5, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Parmesan gehobelt';
  update prep_items set todo_minutes = 12, check_minutes = 3, finish_minutes = 5 where dish_id = v_dish_id and name = 'Ceasar Dressing';
  update prep_items set todo_minutes = 17, check_minutes = 2, finish_minutes = 6 where dish_id = v_dish_id and name = 'Speck';
  update prep_items set todo_minutes = 14, check_minutes = 2, finish_minutes = 5 where dish_id = v_dish_id and name = 'Croutons';
  update prep_items set todo_minutes = 9, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Kräutersalat';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Gegrillter Oktopus';
  update prep_items set todo_minutes = 16, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Oktopus';
  update prep_items set todo_minutes = 14, check_minutes = 2, finish_minutes = 6 where dish_id = v_dish_id and name = 'Peperoni geschmort';
  update prep_items set todo_minutes = 10, check_minutes = 3, finish_minutes = 5 where dish_id = v_dish_id and name = 'Fenchelshavings';
  update prep_items set todo_minutes = 9, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Spinat';
  update prep_items set todo_minutes = 6, check_minutes = 3, finish_minutes = 5 where dish_id = v_dish_id and name = 'Sherry Dressing';
  update prep_items set todo_minutes = 7, check_minutes = 2, finish_minutes = 3 where dish_id = v_dish_id and name = 'Knoblauch geröstet';
  update prep_items set todo_minutes = 12, check_minutes = 2, finish_minutes = 3 where dish_id = v_dish_id and name = 'Taggiasca Oliven';
  update prep_items set todo_minutes = 15, check_minutes = 1, finish_minutes = 6 where dish_id = v_dish_id and name = 'Blattpetersilie';
  update prep_items set todo_minutes = 14, check_minutes = 2, finish_minutes = 5 where dish_id = v_dish_id and name = 'Minze';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Wagyu Steak Salat';
  update prep_items set todo_minutes = 16, check_minutes = 2, finish_minutes = 6 where dish_id = v_dish_id and name = 'Wagyu Steak';
  update prep_items set todo_minutes = 14, check_minutes = 2, finish_minutes = 3 where dish_id = v_dish_id and name = 'Avocado (reif)';
  update prep_items set todo_minutes = 18, check_minutes = 1, finish_minutes = 4 where dish_id = v_dish_id and name = 'Jungspinat';
  update prep_items set todo_minutes = 12, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Chimichurri';
  update prep_items set todo_minutes = 5, check_minutes = 3, finish_minutes = 5 where dish_id = v_dish_id and name = 'Zwiebelknusper';
  update prep_items set todo_minutes = 15, check_minutes = 3, finish_minutes = 6 where dish_id = v_dish_id and name = 'Radieschen';
  update prep_items set todo_minutes = 18, check_minutes = 2, finish_minutes = 5 where dish_id = v_dish_id and name = 'Limetten Dressing';
  update prep_items set todo_minutes = 16, check_minutes = 2, finish_minutes = 5 where dish_id = v_dish_id and name = 'Kräutersalat';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Cote de Boeuf';
  update prep_items set todo_minutes = 5, check_minutes = 2, finish_minutes = 4 where dish_id = v_dish_id and name = 'Morucha Rind';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Kalbsspare ribs';
  update prep_items set todo_minutes = 7, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Holzen Kalb';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Kotlett Luma Schwein';
  update prep_items set todo_minutes = 12, check_minutes = 1, finish_minutes = 3 where dish_id = v_dish_id and name = 'Luma Schwein';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'US BEEF Flanksteak';
  update prep_items set todo_minutes = 17, check_minutes = 2, finish_minutes = 4 where dish_id = v_dish_id and name = 'US Beef Flank';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Wagyu Burger';
  update prep_items set todo_minutes = 16, check_minutes = 1, finish_minutes = 5 where dish_id = v_dish_id and name = 'Burger Patty';
  update prep_items set todo_minutes = 11, check_minutes = 2, finish_minutes = 3 where dish_id = v_dish_id and name = 'Burger Bun';
  update prep_items set todo_minutes = 7, check_minutes = 2, finish_minutes = 4 where dish_id = v_dish_id and name = 'Lattich';
  update prep_items set todo_minutes = 13, check_minutes = 2, finish_minutes = 3 where dish_id = v_dish_id and name = 'Tomate';
  update prep_items set todo_minutes = 18, check_minutes = 2, finish_minutes = 7 where dish_id = v_dish_id and name = 'Gurke';
  update prep_items set todo_minutes = 9, check_minutes = 3, finish_minutes = 5 where dish_id = v_dish_id and name = 'BBQ Sauce';
  update prep_items set todo_minutes = 10, check_minutes = 3, finish_minutes = 5 where dish_id = v_dish_id and name = 'Zwiebel-Jalapeno Relish';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Ribelmais-Poularde';
  update prep_items set todo_minutes = 8, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Schenkelsteak';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Thunfisch';
  update prep_items set todo_minutes = 7, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Thunfisch';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Planted Steak';
  update prep_items set todo_minutes = 15, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Planted Steak';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Allumettes';
  update prep_items set todo_minutes = 12, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Pommes Allumettes';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Baked Potato';
  update prep_items set todo_minutes = 9, check_minutes = 2, finish_minutes = 3 where dish_id = v_dish_id and name = 'Ofenkartoffel';
  update prep_items set todo_minutes = 7, check_minutes = 2, finish_minutes = 4 where dish_id = v_dish_id and name = 'Thymian & Pecorino';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Trüffel Mac and Cheese';
  update prep_items set todo_minutes = 14, check_minutes = 3, finish_minutes = 5 where dish_id = v_dish_id and name = 'Maccheroncini';
  update prep_items set todo_minutes = 7, check_minutes = 3, finish_minutes = 4 where dish_id = v_dish_id and name = 'Mac & Cheese Sauce';
  update prep_items set todo_minutes = 12, check_minutes = 3, finish_minutes = 5 where dish_id = v_dish_id and name = 'Trüffel & Parmesan';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Waldpilze';
  update prep_items set todo_minutes = 11, check_minutes = 2, finish_minutes = 4 where dish_id = v_dish_id and name = 'Konfierte Waldpilze';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Tomatensalat';
  update prep_items set todo_minutes = 6, check_minutes = 2, finish_minutes = 4 where dish_id = v_dish_id and name = 'Cherry Tomaten Mix';
  update prep_items set todo_minutes = 5, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Stracciatella';
  update prep_items set todo_minutes = 8, check_minutes = 2, finish_minutes = 3 where dish_id = v_dish_id and name = 'Basilikum-Pesto';
  update prep_items set todo_minutes = 6, check_minutes = 2, finish_minutes = 3 where dish_id = v_dish_id and name = 'Pinienkerne';

  select id into v_dish_id from prep_dishes where station = 'SKY' and name = 'Gerösteter Blumenkohl';
  update prep_items set todo_minutes = 6, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Blumenkohl geröstet';
  update prep_items set todo_minutes = 13, check_minutes = 1, finish_minutes = 4 where dish_id = v_dish_id and name = 'Yuzu-Nussbutter';
  update prep_items set todo_minutes = 14, check_minutes = 1, finish_minutes = 2 where dish_id = v_dish_id and name = 'Sonnenblumenkerne';

end $$;
