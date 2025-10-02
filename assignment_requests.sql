-- Assignment requests: technician invites farmer to join their firm
begin;

create table if not exists public.assignment_requests (
  id             uuid primary key default gen_random_uuid(),
  technician_id  uuid not null references public.profiles(id) on delete cascade,
  farmer_id      uuid not null references public.profiles(id) on delete cascade,
  status         text not null check (status in ('pending','accepted','declined')) default 'pending',
  created_at     timestamptz not null default now(),
  unique (technician_id, farmer_id, status)
);

alter table public.assignment_requests enable row level security;

-- Policies: technicians can manage their outgoing; farmers can read/respond to incoming
drop policy if exists "ar technician select" on public.assignment_requests;
create policy "ar technician select" on public.assignment_requests
for select using (technician_id = auth.uid());

drop policy if exists "ar farmer select" on public.assignment_requests;
create policy "ar farmer select" on public.assignment_requests
for select using (farmer_id = auth.uid());

drop policy if exists "ar technician insert" on public.assignment_requests;
create policy "ar technician insert" on public.assignment_requests
for insert with check (technician_id = auth.uid());

drop policy if exists "ar technician update" on public.assignment_requests;
create policy "ar technician update" on public.assignment_requests
for update using (technician_id = auth.uid()) with check (technician_id = auth.uid());

drop policy if exists "ar farmer respond" on public.assignment_requests;
create policy "ar farmer respond" on public.assignment_requests
for update using (farmer_id = auth.uid()) with check (farmer_id = auth.uid());

-- Optional: let farmers see their pending requests even if the row was just inserted
-- (select is already allowed to farmer_id)

-- Convenience: allow technician to re-send a request if previous was declined
drop policy if exists "ar technician upsert declined" on public.assignment_requests;
create policy "ar technician upsert declined" on public.assignment_requests
for insert with check (
  technician_id = auth.uid()
);

-- When a request is accepted, create the assignment link if missing
create or replace function public.ar_on_accept_upsert_link()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'accepted' and (old.status is distinct from 'accepted') then
    insert into public.technician_farmers(technician_id, farmer_id)
    values (new.technician_id, new.farmer_id)
    on conflict do nothing;
  end if;
  return new;
end $$;

drop trigger if exists trg_ar_on_accept on public.assignment_requests;
create trigger trg_ar_on_accept
after update on public.assignment_requests
for each row execute function public.ar_on_accept_upsert_link();

commit;


