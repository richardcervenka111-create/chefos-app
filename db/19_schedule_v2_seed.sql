-- Sautero — real shift codes and staff roster, from Richard's actual Hotel Schweizerhof
-- Bern AG kitchen team roster (06.07.2026-26.07.2026). Run after 18_schedule_v2_schema.sql.

-- Shift codes (with real hours from the roster's own legend)
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'FE', 'Ferien', NULL, NULL, NULL, NULL, NULL, true, 0);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'FI', 'Feier', NULL, NULL, NULL, NULL, NULL, true, 1);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'FK', 'Frei (kompensation)', NULL, NULL, NULL, NULL, NULL, true, 2);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'FR', 'Frei', NULL, NULL, NULL, NULL, NULL, true, 3);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'MI', 'Militär', NULL, NULL, NULL, NULL, NULL, true, 4);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'MV', 'Mutterschaft / Vaterschaft', NULL, NULL, NULL, NULL, NULL, true, 5);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SC', 'Schule', NULL, NULL, NULL, NULL, NULL, true, 6);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'ATEIL', 'Azubi Teildienst', '10:15', '14:24', '17:15', '21:30', NULL, false, 7);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'BDDF', 'BQT Frühdienst', '09:00', '18:24', NULL, NULL, '10:45-11:15 · 15:00-15:30', false, 8);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'BDDM', 'BQT Mitteldienst', '11:30', '20:54', NULL, NULL, '14:00-14:30 · 17:30-18:00', false, 9);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'PJFR', 'Pass JAX Früh', '08:00', '16:54', NULL, NULL, '10:30-11:00', false, 10);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'PJM', 'Pass Jax Mittel', '11:30', '20:24', NULL, NULL, '14:00-14:30', false, 11);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'PJSP', 'Pass Jax Spät', '13:30', '22:24', NULL, NULL, '17:30-18:00', false, 12);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'JTD', 'JAX Teildienst', '10:30', '14:00', '17:30', '22:24', NULL, false, 13);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'J0830', 'JAX 8:30-17:24', '08:30', '17:24', NULL, NULL, '14:00-14:30', false, 14);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'J1430', 'JAX 14:30-23:24', '14:30', '23:24', NULL, NULL, '17:00-17:30', false, 15);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'J1030', 'JAX 10:30-19:24', '10:30', '19:24', NULL, NULL, '14:00-14:30', false, 16);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'H0930', 'JAX halber Tag 9:30-13:42', '09:30', '13:42', NULL, NULL, NULL, false, 17);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'H1800', 'JAX halber Tag 18:00-22:12', '18:00', '22:12', NULL, NULL, NULL, false, 18);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'BKFST', 'Frühstücksdienst', '06:00', '14:54', NULL, NULL, '11:00-11:30', false, 19);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'TDSKY', 'Sky Split', '10:30', '14:00', '17:30', '22:24', NULL, false, 20);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'MDSKY', 'Sky middle', '11:30', '20:24', NULL, NULL, '14:00-14:30', false, 21);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'SPSKY', 'SKY Late', '14:00', '22:54', NULL, NULL, '17:00-17:30', false, 22);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'PDDF', 'Pastry Frühdienst', '09:00', '17:54', NULL, NULL, '10:45-11:15', false, 23);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'PDDM', 'Pastry Mitteldienst', '11:30', '20:54', NULL, NULL, '14:00-14:30 · 17:30-18:00', false, 24);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'PDDS', 'Pastry Spätdienst', '14:00', '22:54', NULL, NULL, '17:30-18:00', false, 25);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'PTD', 'Pastry Teildienst', '10:00', '14:30', '18:30', '22:24', NULL, false, 26);
insert into shift_codes (kitchen_id, code, label, start_time, end_time, second_start_time, second_end_time, break_note, is_absence, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Adm.', 'Admin Dienst', '08:00', '16:54', NULL, NULL, '12:00-12:30', false, 27);

-- Staff roster
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Haseloh Andreas', 'Management', 0);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Koltes Stephan', 'Management', 1);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Sargenti Rojas Emmanuel', 'Management', 2);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Degni Valeria', 'Management', 3);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Chernysheva Anna', 'SKY', 4);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Cervenka Richard', 'SKY', 5);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Casabar Jasper Ptolemy', 'SKY', 6);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'May Marvin Aaron', 'Bankett', 7);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Passi Enrica', 'Bankett', 8);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Asdecker Ulf', 'Bankett', 9);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Aushilfe Adia (BQT KIT)', 'Bankett', 10);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Aliouat Garrido Karim', 'Saucier', 11);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Christodoulou Efthymios Prokopios', 'Saucier', 12);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Cosentino Paz Tiziano', 'Saucier', 13);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Castro Cj', 'Entremetier', 14);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Lareza Beatriz Isabel', 'Entremetier', 15);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Rodriguez Diego', 'Gardemanger', 16);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Galea Mena Ana Isabel', 'Gardemanger', 17);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Figueiredo Mora', 'Gardemanger', 18);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Favennec Karl', 'Patisserie', 19);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Scott Robin', 'Patisserie', 20);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Chen Cheryll', 'Patisserie', 21);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Sittinan Ploy', 'Patisserie', 22);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Ponnampalam Sivaganesan', 'Frühstück', 23);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Acharya Sandeep', 'Frühstück', 24);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Werner Lars', 'Frühstück', 25);
insert into staff_members (kitchen_id, name, section, sort_order) values ('11111111-1111-4111-8111-111111111111', 'Sohsungnoen Tanetpon', 'Frühstück', 26);
