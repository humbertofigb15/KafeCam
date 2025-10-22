-- CRITICAL FIX FOR AVATAR STORAGE
-- Run this in Supabase SQL Editor with service role

-- 1. First, ensure the avatars bucket exists and is private
-- Go to Storage > Buckets and verify 'avatars' bucket exists
-- Make sure it's set to PRIVATE (not public)

-- 2. Clean up ALL existing avatar policies to start fresh
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname LIKE '%avatar%'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
    END LOOP;
END $$;

-- 3. Create simple, working policies for avatars
-- Allow authenticated users to read all avatars
CREATE POLICY "avatars_read_all"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'avatars');

-- Allow users to upload their own avatars (both uppercase and lowercase UUID)
CREATE POLICY "avatars_insert_own"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars' 
    AND (
        -- Lowercase UUID
        name ~ ('^' || lower(auth.uid()::text) || '(-avatar)?\.') 
        OR 
        -- Uppercase UUID (for backward compatibility)
        name ~ ('^' || upper(replace(auth.uid()::text, '-', '')) || '(-avatar)?\.')
        OR
        -- Standard UUID format
        name ~ ('^' || auth.uid()::text || '(-avatar)?\.')
    )
);

-- Allow users to update their own avatars
CREATE POLICY "avatars_update_own"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars' 
    AND (
        name ~ ('^' || lower(auth.uid()::text) || '(-avatar)?\.') 
        OR name ~ ('^' || upper(replace(auth.uid()::text, '-', '')) || '(-avatar)?\.')
        OR name ~ ('^' || auth.uid()::text || '(-avatar)?\.')
    )
)
WITH CHECK (
    bucket_id = 'avatars' 
    AND (
        name ~ ('^' || lower(auth.uid()::text) || '(-avatar)?\.') 
        OR name ~ ('^' || upper(replace(auth.uid()::text, '-', '')) || '(-avatar)?\.')
        OR name ~ ('^' || auth.uid()::text || '(-avatar)?\.')
    )
);

-- Allow users to delete their own avatars
CREATE POLICY "avatars_delete_own"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars' 
    AND (
        name ~ ('^' || lower(auth.uid()::text) || '(-avatar)?\.') 
        OR name ~ ('^' || upper(replace(auth.uid()::text, '-', '')) || '(-avatar)?\.')
        OR name ~ ('^' || auth.uid()::text || '(-avatar)?\.')
    )
);

-- 4. Verify policies are created
SELECT policyname, cmd, permissive
FROM pg_policies
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE 'avatars_%'
ORDER BY policyname;
