-- Sautero — one-off fix (Richard, 16.7.): chefos@protonmail.com was created earlier today
-- through the OLD friend-QR flow (before the personal-invites-are-social change), which pulled
-- it into Richard's own kitchen — so it still sees his Check List projects ("Burito").
--
-- This moves the account into its own brand-new kitchen, exactly what the fixed flow
-- (db/110's ensure_personal_kitchen) would have done: the kitchens-insert triggers seed the
-- Sautero ingredient + recipe shelves automatically, Check List starts empty. The friendship
-- connection (chef_connections) is untouched. Takes effect on the account's next page load.

do $$
declare
  v_user uuid;
  v_kitchen uuid;
begin
  select id into v_user from auth.users where email = 'chefos@protonmail.com';
  if v_user is null then
    raise exception 'No user with that email — nothing changed.';
  end if;
  insert into kitchens (name, created_by) values ('My Kitchen', v_user) returning id into v_kitchen;
  update profiles set kitchen_id = v_kitchen where id = v_user;
end $$;
