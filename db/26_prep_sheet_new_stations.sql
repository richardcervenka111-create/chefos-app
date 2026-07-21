-- Sautero — prep sheets for Hot Line, Garde Manger, and Desserts, built the same way as SKY.
-- Source: Richard's real menu documents — 'Frühlingskarte Beschreib 2026.pdf' (Hotel Schweizerhof
-- spring menu, 18 dishes) and 'Küche beschreibung Menu 2.docx' (4-course tasting menu). No CHF
-- prices were given for these dishes (unlike SKY), so price is left NULL. Station assignment
-- (cold starters/salads -> Garde Manger, hot mains -> Hot Line, desserts -> Desserts) is Richard's
-- own approved judgment call, not from the source documents.
-- min_required (3-6) and todo/check/finish_minutes are the same random-placeholder pattern used
-- for SKY -- not real par levels or timings, adjust per item in the app.

do $$
declare
  v_dish_id uuid;
begin
  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Garde Manger', 'Grüne Salatspitzen', NULL, 0) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräutersalatspitzen', 0, 6, 18, 3, 7);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'French Dressing', 1, 6, 13, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Italienische Sauce', 2, 4, 17, 3, 7);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Haus-Sauce (Honig-Senf)', 3, 4, 6, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Essig/Öl Dressing', 4, 4, 6, 3, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Garde Manger', 'Auberginen Tatar', NULL, 1) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Auberginen-Tatar', 0, 6, 12, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Mojo Rojo', 1, 3, 18, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Mojo Verde', 2, 3, 5, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Geröstete Pinienkerne', 3, 3, 17, 2, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräutersalat', 4, 6, 14, 1, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Parmesanhobel', 5, 4, 15, 2, 6);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Garde Manger', 'Terrine von der Ente', NULL, 2) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Enten-Terrine (Keule/Herz/Brust/Leber/Lardo/Apfel)', 0, 3, 15, 1, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Gepickeltes Gemüse', 1, 5, 11, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Birnensorbet', 2, 5, 10, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Salbeiblüten & Kräuter', 3, 5, 5, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Geröstete Pistazien', 4, 6, 6, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Brioche', 5, 3, 5, 3, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Garde Manger', 'Handgeschnittenes Tatar vom Holzen Angus Rind', NULL, 3) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Rindstatar (Holzen Angus)', 0, 4, 8, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Tischgarnituren (Kondimente für Tischzubereitung)', 1, 6, 16, 2, 6);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Garde Manger', 'Cucumber Gazpacho', NULL, 4) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Cucumber & Green Chili Gazpacho (Pernod/Dill/Verbena/Agastache)', 0, 3, 14, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Pea-Cucumber-Verbena Salad', 1, 5, 10, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Olive Oil', 2, 5, 5, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Creme Fraiche Ice Cream', 3, 4, 8, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Cucumber Blossom', 4, 3, 5, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Buckwheat Cookie', 5, 4, 15, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Buckwheat Croutons', 6, 6, 13, 1, 3);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Knochenmark vom Berner Oberländer Weiderind', NULL, 0) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Knochenmark', 0, 6, 15, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kalbsjus', 1, 6, 11, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Schalotten', 2, 5, 18, 3, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Schnittlauch', 3, 3, 8, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Wildkräutersalat', 4, 3, 5, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Brioche', 5, 6, 9, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Belper Knolle (geraspelt)', 6, 5, 18, 2, 6);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Tomatenconsommé', NULL, 1) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Tomatenconsommé', 0, 3, 6, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Ravioli Dauphinés (Bergricotta gefüllt)', 1, 4, 5, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräuter', 2, 5, 14, 2, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Sardinische Artischocke', NULL, 2) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Erbsen-Artischockenpüree', 0, 6, 18, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Geröstete Mandeln', 1, 6, 7, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Artischocken-Erbsen Salsa', 2, 5, 8, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Sauerampfer Espuma', 3, 4, 7, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Nuss Beurre Blanc', 4, 6, 12, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräuteröl', 5, 6, 5, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Senfblüten', 6, 3, 13, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Geriebene Mandel', 7, 6, 9, 2, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Bärlauch Gnocchi', NULL, 3) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Bärlauch-Gnocchi', 0, 5, 13, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Schlossberger Bergkäse', 1, 4, 8, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Morcheln', 2, 5, 8, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Morchel-Weissweinschaum', 3, 3, 9, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Veilchenblüten', 4, 4, 5, 1, 2);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Makrele im Escabechesud', NULL, 4) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Makrele', 0, 5, 10, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Escabechesud (Kalamansisaft/Olivenöl/Mirepoix)', 1, 3, 10, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Tomaten-Grapefruit-Orange Salat', 2, 5, 15, 3, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Pickles', 3, 4, 14, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Oliven', 4, 6, 10, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräuter', 5, 3, 5, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Speckfond-Peperoni Schaum', 6, 6, 6, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Olivenöl', 7, 5, 7, 1, 2);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Baby Steinbutt aus dem Ofen', NULL, 5) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Baby Steinbutt', 0, 6, 13, 2, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Kräuter', 1, 3, 16, 3, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Saisonales Marktgemüse', 2, 4, 17, 2, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Beilagen & Saucen nach Wahl', 3, 3, 15, 2, 3);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Schweizerhof Coq au Vin Blanc', NULL, 6) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Hühnerbrust (Salzlake, pochiert)', 0, 6, 17, 1, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Trüffel-Pilzduxelles', 1, 3, 14, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Hühnerschenkel (konfiert)', 2, 6, 14, 1, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Geflügelleber', 3, 3, 6, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Apfel', 4, 5, 11, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Speck', 5, 6, 16, 3, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Schwarzer Perigord Trüffel', 6, 6, 12, 2, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Tournierte Champignons', 7, 3, 13, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Coq au Vin Sauce', 8, 5, 14, 1, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Saisongemüse', 9, 3, 8, 3, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Rindsfilet', NULL, 7) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Rindsfilet (Holzen Angus, 200g)', 0, 6, 17, 3, 7);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Sauce Bordelaise', 1, 5, 5, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Rotwein-Zwiebelgel', 2, 4, 15, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Entenleber (Rossini-Option)', 3, 4, 17, 2, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Trüffel', 4, 6, 8, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Blattgold', 5, 5, 8, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Saisongemüse', 6, 4, 8, 2, 3);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Côte de Boeuf vom Morucha Rind', NULL, 8) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Côte de Boeuf (Morucha Rind, ca. 600g/2 Pers.)', 0, 5, 8, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Saisongemüse', 1, 6, 10, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Beilagen & Saucen nach Wahl', 2, 3, 9, 1, 2);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Wild Herb Quiche', NULL, 9) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Wild Herb Quiche Layer (Chickweed/Wild Thyme/Spinach/Ribwort Plantain/Parsley/Wild Garlic)', 0, 6, 12, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Mushroom Layer (Morels/Porcini/Button Mushrooms)', 1, 6, 11, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Quiche Crust (Lemon/Olive Oil)', 2, 5, 16, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Confit Egg Yolk', 3, 5, 6, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Wild Herb Salad', 4, 3, 15, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Stroop Wafer Base', 5, 5, 9, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Mustard French Dressing', 6, 4, 11, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Chive Oil', 7, 3, 17, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Stuffed Morels (Mushroom Farce)', 8, 4, 17, 1, 7);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Hot Line', 'Quail', NULL, 10) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Quail Breast Crepinette', 0, 3, 12, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Quail Leg Confit (Deep Fried)', 1, 3, 15, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Shallot Purée', 2, 6, 9, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Caramelized Endive', 3, 3, 17, 2, 7);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Chicken Skin Cracker', 4, 3, 7, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Polenta-Cream Cheese Croquettes', 5, 5, 13, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Celery Salsa (Saffron)', 6, 6, 18, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Beurre Noisette Foam', 7, 3, 11, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Saffron Sauce', 8, 4, 12, 2, 3);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Desserts', 'Profiterol', NULL, 0) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Choux-Gebäck', 0, 3, 11, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Sauerrahm Eis', 1, 6, 10, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Sauerrahm-Vanille Whipped Ganache', 2, 3, 16, 3, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Caramelized Muscovado Sauce', 3, 3, 8, 1, 3);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Desserts', 'Parfait', NULL, 1) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Bergamotte Eis Parfait', 0, 3, 9, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Biskuit (Mandel/Bergamotte)', 1, 5, 16, 1, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Erdbeerconfit', 2, 3, 5, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Erdbeer Whipped Ganache', 3, 6, 17, 2, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Erdbeer Meringue', 4, 3, 8, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Basilikum Eis', 5, 3, 7, 3, 5);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Desserts', 'Rhabarber', NULL, 2) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Holunderblüten Pannacotta', 0, 4, 12, 1, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Rhabarber Confit/Chips/Gel', 1, 6, 14, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Schwarzer Sesam Cracker', 2, 4, 12, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Whipped Ganache', 3, 4, 13, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Sesam-Zitrone-Vanille Eis', 4, 5, 15, 2, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Desserts', 'Baba au Rhum', NULL, 3) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Baba-Teig (Rum)', 0, 5, 18, 1, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Eisenkraut Mousse', 1, 5, 14, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Eisenkraut Eis', 2, 6, 13, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Honig Hippe', 3, 6, 5, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Honig-Passionsfrucht Gel', 4, 6, 13, 3, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Desserts', 'Schweizerhof Schokoladenmousse', NULL, 4) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Schokoladenmousse (Sambirano 68%)', 0, 6, 6, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Tonkabohnen Choco Creme', 1, 3, 13, 2, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Karamellisierte Haselnüsse', 2, 6, 9, 1, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Haselnusseis', 3, 6, 7, 2, 4);

  insert into prep_dishes (kitchen_id, station, name, price, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Desserts', 'Strawberry Dessert', NULL, 5) returning id into v_dish_id;
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Strawberry Coulis', 0, 6, 13, 2, 3);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Strawberry-Chocolate Tube', 1, 4, 11, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Crumble', 2, 5, 7, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Milk Chocolate Ganache', 3, 3, 8, 1, 2);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Strawberry-Pine Sorbet', 4, 3, 15, 2, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Pine Cream Foam', 5, 5, 8, 3, 5);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Flower Tuille', 6, 3, 12, 3, 4);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Strawberry Compté', 7, 5, 16, 1, 6);
  insert into prep_items (kitchen_id, dish_id, name, sort_order, min_required, todo_minutes, check_minutes, finish_minutes) values ('11111111-1111-4111-8111-111111111111', v_dish_id, 'Isomalt Decoration', 8, 6, 5, 2, 4);

end $$;
