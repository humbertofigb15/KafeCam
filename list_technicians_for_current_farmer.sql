begin;

-- Returns technicians (profiles) assigned to the current farmer (auth.uid())
create or replace function public.list_technicians_for_current_farmer()
returns table (id uuid, name text, phone text, email text)
language sql
security definer
set search_path = public
as $$
  select p.id, p.name, p.phone, p.email
  from public.technician_farmers tf
  join public.profiles p on p.id = tf.technician_id
  where tf.farmer_id = auth.uid();
$$;

commit;


