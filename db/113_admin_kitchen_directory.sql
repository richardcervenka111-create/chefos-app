-- Sautero — Head-admin kitchen directory (Richard, 16.7. večer, bod 3): his Kitchen Reports
-- opens with a list of every kitchen — the name its admin chose + that admin's name/email +
-- member count. SECURITY DEFINER because kitchens' members/admins live behind kitchen-scoped
-- RLS; the function itself refuses anyone but the Head Admin.

create or replace function admin_kitchen_directory()
returns table(kitchen_id uuid, kitchen_name text, admin_name text, admin_email text, member_count bigint)
language sql
security definer
set search_path = public
stable
as $$
  select
    k.id,
    k.name,
    a.full_name,
    a.email,
    (select count(*) from profiles m where m.kitchen_id = k.id)
  from kitchens k
  left join lateral (
    select p.full_name, p.email
    from profiles p
    where p.kitchen_id = k.id
      and (p.is_admin or (p.admin_perms->>'company_admin')::boolean is true)
    order by (p.admin_perms->>'company_admin')::boolean is true desc, p.created_at
    limit 1
  ) a on true
  where is_super_admin()
  order by k.name;
$$;
grant execute on function admin_kitchen_directory() to authenticated;
