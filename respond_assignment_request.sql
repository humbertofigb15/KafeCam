begin;

create or replace function public.respond_assignment_request(req_id uuid, accept boolean)
returns void
language plpgsql
security definer
set search_path = public as $$
declare
  r public.assignment_requests%rowtype;
begin
  select * into r from public.assignment_requests where id = req_id and farmer_id = auth.uid();
  if not found then
    raise exception 'request not found or not yours';
  end if;

  if accept then
    insert into public.technician_farmers(technician_id, farmer_id)
    values (r.technician_id, r.farmer_id)
    on conflict do nothing;
  end if;

  delete from public.assignment_requests where id = r.id;
end $$;

-- Allow farmer to call function (function is definer, but we can restrict via RLS-like check inside)
grant execute on function public.respond_assignment_request(uuid, boolean) to authenticated;

commit;


