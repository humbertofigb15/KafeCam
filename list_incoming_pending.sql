begin;

-- Ensures farmer inbox shows only pending requests (helper; optional)
create or replace function public.list_incoming_pending()
returns table (id uuid, technician_id uuid, farmer_id uuid, created_at timestamptz)
language sql
security definer set search_path = public as $$
  select id, technician_id, farmer_id, created_at
  from public.assignment_requests
  where farmer_id = auth.uid() and status = 'pending'
  order by created_at desc;
$$;

commit;


