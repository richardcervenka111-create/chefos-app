-- Sautero — real SKY prep sheet (dishes + items), from Richard's actual paper prep sheet.
-- Run after 20_prep_sheet_schema.sql. Priority left at the default (3) and prep_time
-- left empty for every item, same as the paper sheet's blank 'status' column — Richard
-- fills those in himself, through the app.

do $$
declare
  v_dish_id uuid;
begin
  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Kopfsalat', 18, 0) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kopfsalatherz', '0.5 Stk', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Wildkräuter', '10g', 1);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Croutons', '15g', 2);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Radieschen', '15g', 3);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Dijon Vinaigrette', '50ml', 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Burrata', 24, 1) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Mini Burrata', '50g', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Inka Tomaten', '150g', 1);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Olivenöl', '10g', 2);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Weisser Balsamico', '5g', 3);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Gegrillter Pfirsich', '50g', 4);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräutersalat', '25g', 5);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Gewürzhonig', '10g', 6);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Sellerie-Apfel Salat', 21, 2) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Castelfranco & Tardivo', 'je 4 Blätter', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Stangensellerie', '75g', 1);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Granny Smith', '75g', 2);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Baumnüsse', '20g', 3);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Roquefort Dressing', '50g', 4);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräutersalat', '10g', 5);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Mini Lattich Caesar', 24, 3) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Mini Lattich Blätter', '150g', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Parmesan gehobelt', '30g', 1);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Ceasar Dressing', '100g', 2);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Speck', '30g', 3);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Croutons', '15g', 4);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräutersalat', '10g', 5);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Gegrillter Oktopus', 27, 4) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Oktopus', '120g', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Peperoni geschmort', '80g', 1);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Fenchelshavings', '40g', 2);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Spinat', '30g', 3);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Sherry Dressing', '50ml', 4);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Knoblauch geröstet', '5g', 5);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Taggiasca Oliven', '10g', 6);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Blattpetersilie', '5g', 7);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Minze', '5g', 8);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Wagyu Steak Salat', 35, 5) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Wagyu Steak', '90g', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Avocado (reif)', '60g', 1);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Jungspinat', '20g', 2);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Chimichurri', '30g', 3);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Zwiebelknusper', '15g', 4);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Radieschen', '10g', 5);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Limetten Dressing', '30ml', 6);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräutersalat', '10g', 7);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Cote de Boeuf', 65, 6) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Morucha Rind', '300g', 0);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Kalbsspare ribs', 52, 7) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Holzen Kalb', '500g', 0);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Kotlett Luma Schwein', 49, 8) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Luma Schwein', '300g', 0);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'US BEEF Flanksteak', 52, 9) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'US Beef Flank', '250g', 0);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Wagyu Burger', 45, 10) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Burger Patty', '140g', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Burger Bun', '1 Stk', 1);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Lattich', '2 Blätter', 2);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Tomate', '2 Scheiben', 3);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Gurke', '3 Scheiben', 4);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'BBQ Sauce', '40g', 5);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Zwiebel-Jalapeno Relish', '40g', 6);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Ribelmais-Poularde', 39, 11) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Schenkelsteak', '250g', 0);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Thunfisch', 49, 12) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Thunfisch', '160g', 0);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Planted Steak', 39, 13) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Planted Steak', '120g', 0);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Allumettes', 9, 14) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Pommes Allumettes', '100g', 0);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Baked Potato', 9, 15) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Ofenkartoffel', '1 Stk', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Thymian & Pecorino', '40g', 1);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Trüffel Mac and Cheese', 9, 16) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Maccheroncini', '120g', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Mac & Cheese Sauce', '80g', 1);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Trüffel & Parmesan', '1 Port.', 2);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Waldpilze', 9, 17) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Konfierte Waldpilze', '100g', 0);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Tomatensalat', 9, 18) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Cherry Tomaten Mix', '200g', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Stracciatella', '40g', 1);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Basilikum-Pesto', '20g', 2);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Pinienkerne', '5g', 3);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Gerösteter Blumenkohl', 9, 19) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Blumenkohl geröstet', '150g', 0);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Yuzu-Nussbutter', '50g', 1);
  insert into prep_items (kitchen_id, dish_id, name, on_hand, sort_order) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Sonnenblumenkerne', '10g', 2);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Cafe de Paris', 6, 20) returning id into v_dish_id;

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Trüffel Mayonnaise', 6, 21) returning id into v_dish_id;

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Chipotle Dip', 6, 22) returning id into v_dish_id;

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Chimichurri', 6, 23) returning id into v_dish_id;

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SKY', 'Schwarzer Knoblauch Dip', 6, 24) returning id into v_dish_id;

end $$;
