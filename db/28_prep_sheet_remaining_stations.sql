-- ChefOS — prep sheets for Lobby, Entremetier, BQT, and Extra.
-- Lobby is built on the REAL concept of the Hotel Schweizerhof Bern Lobby Lounge Bar
-- (Fugu-licensed sushi chef Hironori Takahashi, sashimi/sushi + mezze-style light dishes —
-- schweizerhofbern.com/en/dining/lobby-lounge-bar) but the exact menu is an Issuu flipbook
-- that couldn't be read directly, so these specific dish names are a plausible
-- reconstruction, not verbatim from the real menu. Entremetier, BQT, and Extra have NO real
-- reference at all — Richard explicitly authorized filling these in for presentation
-- purposes only. Replace all of this with real data once available.

do $$
declare
  v_dish_id uuid;
begin
  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Lobby', 'Sashimi Selection', 28, 0) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Thunfisch Sashimi', 0, 5, 18, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Lachs Sashimi', 1, 5, 11, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Wasabi', 2, 4, 16, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Sojasauce', 3, 6, 5, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Eingelegter Ingwer', 4, 3, 6, 1, 3);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Lobby', 'Maki Rollen Auswahl', 24, 1) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Sushi-Reis', 0, 6, 5, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Nori-Blätter', 1, 5, 17, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Gurke', 2, 3, 14, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Avocado', 3, 4, 16, 2, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Lachs', 4, 5, 15, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Thunfisch', 5, 6, 7, 3, 5);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Lobby', 'Mezze Teller', 22, 2) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Hummus', 0, 6, 15, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Baba Ganoush', 1, 4, 17, 1, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Marinierte Oliven', 2, 5, 15, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Fladenbrot', 3, 3, 6, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Feta', 4, 3, 14, 2, 5);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Lobby', 'Edamame', 9, 3) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Edamame-Bohnen', 0, 5, 6, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Meersalz', 1, 5, 17, 2, 7);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Lobby', 'Club Sandwich', 26, 4) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Toastbrot', 0, 4, 9, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Pouletbrust', 1, 3, 16, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Speck', 2, 5, 13, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Salat', 3, 6, 7, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Tomate', 4, 3, 15, 2, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Mayonnaise', 5, 3, 7, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Pommes Frites', 6, 4, 17, 3, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Lobby', 'Lobby Burger', 29, 5) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Burger Patty', 0, 6, 16, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Burger Bun', 1, 3, 17, 2, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Cheddar', 2, 4, 5, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Salat', 3, 6, 13, 1, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Tomate', 4, 5, 8, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Burger Sauce', 5, 4, 16, 3, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Pommes Frites', 6, 4, 9, 1, 3);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Entremetier', 'Kürbissuppe', 12, 0) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kürbis', 0, 4, 5, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Gemüsebouillon', 1, 6, 18, 1, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Rahm', 2, 6, 6, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kürbiskernöl', 3, 5, 11, 2, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Entremetier', 'Geröstetes Saisongemüse', 10, 1) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Saisongemüse', 0, 3, 18, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Olivenöl', 1, 3, 15, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräuter', 2, 6, 8, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Meersalz', 3, 5, 13, 3, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Entremetier', 'Rösti', 8, 2) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kartoffeln', 0, 4, 13, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Butter', 1, 5, 5, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Salz', 2, 3, 17, 1, 7);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Entremetier', 'Pilzrisotto', 24, 3) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Risottoreis', 0, 6, 8, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Gemischte Pilze', 1, 4, 15, 2, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Parmesan', 2, 3, 11, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Weisswein', 3, 6, 14, 3, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Gemüsebouillon', 4, 4, 13, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Butter', 5, 5, 6, 1, 2);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Entremetier', 'Spiegelei-Teller', 14, 4) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Eier', 0, 6, 11, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Speck', 1, 6, 14, 2, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Toast', 2, 5, 11, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Schnittlauch', 3, 5, 10, 1, 3);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'BQT', 'Bankett Vorspeisenteller', NULL, 0) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Geräucherter Lachs', 0, 3, 11, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Rindscarpaccio', 1, 5, 13, 2, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Salatgarnitur', 2, 3, 11, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kapern', 3, 4, 13, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Vinaigrette', 4, 6, 6, 2, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'BQT', 'Bankett Poularde', NULL, 1) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Poulardenbrust', 0, 3, 18, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Geflügeljus', 1, 3, 8, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Gemüsegarnitur', 2, 3, 11, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kartoffelgratin', 3, 4, 10, 3, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'BQT', 'Bankett Dessertteller', NULL, 2) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Mousse nach Saison', 0, 3, 7, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Frische Früchte', 1, 5, 9, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Guetzli', 2, 4, 5, 1, 2);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'BQT', 'Buffet Salatbar', NULL, 3) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Gemischte Salate', 0, 3, 7, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Dressings nach Wahl', 1, 5, 12, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Toppings (Nüsse/Croutons/Käse)', 2, 3, 18, 1, 6);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Extra', 'Mitarbeiteressen', NULL, 0) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Tagesgericht Personal', 0, 3, 10, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Beilage', 1, 5, 6, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Salat', 2, 4, 11, 2, 3);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Extra', 'Amuse Bouche', NULL, 1) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Häppchen nach Wahl des Küchenchefs', 0, 6, 15, 2, 4);

end $$;
