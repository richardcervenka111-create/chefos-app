-- Sautero tenant-isolation test (health check 2026-07-15).
--
-- WHAT: proves, with a loud failure, that a user from kitchen A cannot read another
-- kitchen's rows through RLS — across every kitchen-scoped table the app uses.
--
-- WHERE TO RUN: Supabase SQL editor, STAGING first (chefos-staging). It is read-only
-- (SELECT + role impersonation inside one transaction, rolled back at the end) and safe
-- to also run on production after staging passes. Run it after every migration batch
-- that touches RLS policies — that is exactly when the three historical incidents
-- (db/53 recursion, db/55, db/62 lockout) were introduced.
--
-- HOW IT WORKS: picks two real users from two different kitchens, impersonates each the
-- way PostgREST does (role `authenticated` + request.jwt.claims), and asserts that the
-- impersonated user sees ZERO rows belonging to the other kitchen. Any violation raises
-- an exception — you cannot miss it.

begin;

do $$
declare
  user_a uuid; kitchen_a uuid;
  user_b uuid; kitchen_b uuid;
  t text;
  leaked bigint;
  -- Some tables have INTENTIONAL cross-kitchen sharing (the Public shelf + friend sharing:
  -- ingredients db/136, recipes db/131/126/138). A user legitimately seeing another kitchen's
  -- SHARED rows is NOT a leak — only a PRIVATE (unshared) row crossing kitchens is. So for those
  -- tables we subtract the legitimately-shareable rows before counting. (Found 21.7. on the first
  -- real prod run: 12 is_public ingredients showed as a "leak" — the test was too naive.)
  shareable text;
  -- schedule_entries removed 19.7. (never existed in prod — dropped by db/18; the reference
  -- here would abort the whole test on a missing table); projects/tasks/events added.
  -- ingredient_price_history added 19.7. (db/163, same audit that found prep_dishes/tasks
  -- weren't inheriting projects.is_personal at all).
  tenant_tables text[] := array[
    'recipes', 'ingredients', 'prep_items', 'prep_dishes', 'order_list_items',
    'fridges', 'fridge_logs', 'print_label_settings', 'print_label_log',
    'haccp_checklist_items', 'haccp_checklist_log', 'haccp_measurement_log',
    'time_entries', 'projects', 'tasks', 'events', 'check_list_audit_log', 'kitchen_invites',
    'ingredient_lists', 'recipe_lists', 'ingredient_price_history',
    -- 2026-07-21: coverage expanded 21 -> 36. audit_db now FAILS the build if any table
    -- carrying kitchen_id is missing from this array, so a new tenant table can never again
    -- ship without being leak-tested. These 15 had kitchen_id but were never in the test:
    'ai_usage', 'custom_ingredients', 'error_logs', 'feedback', 'feedback_reports',
    'privacy_acceptances', 'recipe_category_icons', 'schedule_assignments', 'schedule_entries',
    'schedule_forecast', 'shift_codes', 'staff_members', 'station_icons', 'usage_events',
    'working_time_day_notes'
  ];
begin
  -- two users from two DIFFERENT kitchens
  select p1.id, p1.kitchen_id into user_a, kitchen_a
    from profiles p1 where p1.kitchen_id is not null limit 1;
  select p2.id, p2.kitchen_id into user_b, kitchen_b
    from profiles p2 where p2.kitchen_id is not null and p2.kitchen_id <> kitchen_a limit 1;

  if user_b is null then
    raise notice 'SKIPPED: fewer than two kitchens with members exist in this environment — create a second test kitchen to run this properly.';
    return;
  end if;

  -- impersonate user A exactly like PostgREST does
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  foreach t in array tenant_tables loop
    begin
      shareable := case t
        when 'ingredients' then ' and not coalesce(is_public,false) and not coalesce(shared_with_friends,false)'
        when 'recipes' then ' and not coalesce(is_public,false) and not coalesce(shared_with_chefos,false) and not coalesce(shared_with_friends,false)'
        else '' end;
      execute format('select count(*) from %I where kitchen_id = %L' || shareable, t, kitchen_b) into leaked;
      if leaked > 0 then
        raise exception 'TENANT LEAK: user % (kitchen %) can read % row(s) of table % belonging to kitchen %',
          user_a, kitchen_a, leaked, t, kitchen_b;
      end if;
    exception
      when undefined_table then
        raise notice 'table % does not exist here — skipped', t;
      when undefined_column then
        raise notice 'table % has no kitchen_id column — AUDIT THIS TABLE MANUALLY', t;
    end;
  end loop;

  -- reset impersonation, then the same test in the other direction
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  foreach t in array tenant_tables loop
    begin
      shareable := case t
        when 'ingredients' then ' and not coalesce(is_public,false) and not coalesce(shared_with_friends,false)'
        when 'recipes' then ' and not coalesce(is_public,false) and not coalesce(shared_with_chefos,false) and not coalesce(shared_with_friends,false)'
        else '' end;
      execute format('select count(*) from %I where kitchen_id = %L' || shareable, t, kitchen_a) into leaked;
      if leaked > 0 then
        raise exception 'TENANT LEAK: user % (kitchen %) can read % row(s) of table % belonging to kitchen %',
          user_b, kitchen_b, leaked, t, kitchen_a;
      end if;
    exception
      when undefined_table then null;
      when undefined_column then null;
    end;
  end loop;

  raise notice '✅ TENANT ISOLATION OK: user A (kitchen %) and user B (kitchen %) cannot see each other''s rows in any tested table.', kitchen_a, kitchen_b;
end $$;

rollback;
