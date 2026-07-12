-- ChefOS — fix for "Database error saving new user" on first login
-- Run this once in the Supabase SQL Editor. It replaces the auto-profile-on-signup
-- function from 01_schema.sql with a version that explicitly points at the "public"
-- schema, instead of relying on it being found automatically (which doesn't always
-- work in the background process that creates new accounts).

create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, kitchen_id)
  values (new.id, (select id from public.kitchens order by created_at asc limit 1));
  return new;
end;
$$ language plpgsql security definer set search_path = public;
