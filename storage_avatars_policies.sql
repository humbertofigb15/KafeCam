-- Supabase Storage RLS policies for avatars bucket
-- Usage: Run in SQL editor (service role or owner). Safe to re-run.

-- Ensure only one definition by dropping first
drop policy if exists "avatars_select_authenticated" on storage.objects;
drop policy if exists "avatars_insert_owner" on storage.objects;
drop policy if exists "avatars_update_owner" on storage.objects;
drop policy if exists "avatars_delete_owner" on storage.objects;

-- READ: any authenticated user may read from avatars bucket
create policy "avatars_select_authenticated"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'avatars'
  );

-- INSERT: only allow the logged-in user to upload files whose name starts with their user id
-- e.g., <uid>.jpg, <uid>-timestamp.jpg, <uid>-avatar.png, or under folders like <uid>/...
create policy "avatars_insert_owner"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (
      -- allow root-level names starting with uid
      name like (auth.uid()::text || '%')
      or
      -- allow folder prefixes like "<uid>/..."
      name like (auth.uid()::text || '/%')
    )
  );

-- UPDATE: owners can overwrite their own files (used for upserts and stable key refresh)
create policy "avatars_update_owner"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'avatars' and (
      name like (auth.uid()::text || '%') or name like (auth.uid()::text || '/%')
    )
  )
  with check (
    bucket_id = 'avatars' and (
      name like (auth.uid()::text || '%') or name like (auth.uid()::text || '/%')
    )
  );

-- DELETE: owners can delete their own files if needed
create policy "avatars_delete_owner"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'avatars' and (
      name like (auth.uid()::text || '%') or name like (auth.uid()::text || '/%')
    )
  );


