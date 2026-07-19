-- Sautero — ingredient lists + recipe projects: personal/company privacy split (2026-07-19,
-- found during the feature-verification sweep while re-investigating Richard's earlier report
-- "v ingredients keď som v personal účte a vytvorím novú kategóriu tak ju vidí každý").
--
-- db/146 (ingredient_lists) and db/147 (recipe_lists) made every custom list/project visible
-- to the whole kitchen, on the false premise that "a personal kitchen has exactly one member"
-- — exactly the mistake already fixed for order_list_items (db/156), projects (db/159) and
-- events (db/161): kitchen_id is fixed to a team member's COMPANY kitchen even while they are
-- just displaying the app in "personal" mode, so a list created while toggled to Personal was
-- written straight into the shared kitchen_id bucket and shown to every teammate.
--
-- Backfill: only 2 rows exist today (both Richard's own test lists, 18.7., 0 in recipe_lists)
-- — defaulted to is_personal = true (creator-only) per the standing rule "privacy wins when in
-- doubt", not because the data showed anything sensitive.
--
-- Creation stays open to any kitchen member, unchanged (db/146/147's own "parity with recipe
-- projects" reasoning — never admin-gated like Check List projects were).

alter table ingredient_lists add column if not exists is_personal boolean not null default true;
alter table recipe_lists add column if not exists is_personal boolean not null default true;

drop policy if exists "read kitchen ingredient lists" on ingredient_lists;
create policy "read kitchen ingredient lists" on ingredient_lists for select using (
  (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  or created_by = auth.uid()
);
-- insert/update/delete stay exactly as db/146 left them (creator-only, unrestricted create).

drop policy if exists "read kitchen recipe lists" on recipe_lists;
create policy "read kitchen recipe lists" on recipe_lists for select using (
  (not is_personal and kitchen_id in (select kitchen_id from profiles where id = auth.uid()))
  or created_by = auth.uid()
);
-- insert/update/delete stay exactly as db/147 left them.

-- List-linked items: only readable kitchen-wide when their PARENT LIST is itself company-mode
-- (not is_personal) — a personal-mode list's items must stay exactly as private as the list.
-- db/114's friend-sharing policies (separate, additive, `shared` column) are untouched.
drop policy if exists "read kitchen ingredients" on ingredients;
create policy "read kitchen ingredients" on ingredients for select using (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    and (not is_personal
         or (list_id is not null and list_id in (select id from ingredient_lists where not is_personal))))
  or created_by = auth.uid()
);

drop policy if exists "read kitchen recipes" on recipes;
create policy "read kitchen recipes" on recipes for select using (
  (kitchen_id in (select kitchen_id from profiles where id = auth.uid())
    and (not is_personal
         or (list_id is not null and list_id in (select id from recipe_lists where not is_personal))))
  or created_by = auth.uid()
);
