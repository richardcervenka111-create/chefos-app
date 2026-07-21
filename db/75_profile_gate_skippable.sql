-- Sautero — My Profile gate must be skippable, not force a real name (bod 4, 2026-07-14).
--
-- Richard: "musí byť optional profil info - nie povinne reálne meno." The name field was always
-- free text (nothing ever checked it was someone's REAL legal name), but the gate itself
-- couldn't be passed at all without filling name+age+gender. Adds a flag so "I skipped this" is
-- remembered and the gate doesn't reappear every single login.

alter table profiles add column if not exists profile_gate_skipped boolean not null default false;
