begin;

-- Search farmer by exact full name and phone
-- SECURITY DEFINER so RLS on profiles does not block the exact match lookup
create or replace function public.search_farmer_exact(p_name text, p_phone text)
returns table (id uuid, name text, phone text, email text)
language sql
security definer
set search_path = public
as $$
  select id, name, phone, email
  from public.profiles
  where role = 'farmer'
    and name  = p_name
    and phone = p_phone
  limit 1;
$$;

comment on function public.search_farmer_exact(text,text) is 'Returns farmer row by exact (name, phone). Limited columns.';

commit;


