-- FIX CAPTURES STORAGE POLICIES
-- Run this in Supabase SQL Editor

-- 1. Clean up existing captures policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND policyname LIKE '%capture%'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
    END LOOP;
END $$;

-- 2. Create working policies for captures bucket

-- Allow authenticated users to read all captures
CREATE POLICY "captures_read_all"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'captures');

-- Allow users to upload captures to any folder (since we use user names as folders)
-- The folder name could be the user's full name or their UUID
CREATE POLICY "captures_insert_auth"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'captures'
);

-- Allow users to update their own captures
-- This checks if the path starts with their UUID or contains their UUID
CREATE POLICY "captures_update_own"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'captures'
    AND (
        -- Path starts with user's UUID
        name ~ ('^' || auth.uid()::text || '/')
        -- Or path contains the user's UUID somewhere (for flexibility)
        OR name ~ auth.uid()::text
    )
)
WITH CHECK (
    bucket_id = 'captures'
);

-- Allow users to delete their own captures
CREATE POLICY "captures_delete_own"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'captures'
    AND (
        name ~ ('^' || auth.uid()::text || '/')
        OR name ~ auth.uid()::text
    )
);

-- 3. Ensure the captures table has proper RLS policies
-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "captures_insert_own" ON public.captures;
DROP POLICY IF EXISTS "captures_select_all" ON public.captures;
DROP POLICY IF EXISTS "captures_update_own" ON public.captures;
DROP POLICY IF EXISTS "captures_delete_own" ON public.captures;

-- Allow users to insert their own captures
CREATE POLICY "captures_insert_own"
ON public.captures FOR INSERT
TO authenticated
WITH CHECK (uploaded_by_user_id = auth.uid()::text);

-- Allow users to read all captures (or restrict to own if needed)
CREATE POLICY "captures_select_all"
ON public.captures FOR SELECT
TO authenticated
USING (true);  -- Change to (uploaded_by_user_id = auth.uid()::text) if you want users to see only their own

-- Allow users to update their own captures
CREATE POLICY "captures_update_own"
ON public.captures FOR UPDATE
TO authenticated
USING (uploaded_by_user_id = auth.uid()::text)
WITH CHECK (uploaded_by_user_id = auth.uid()::text);

-- Allow users to delete their own captures
CREATE POLICY "captures_delete_own"
ON public.captures FOR DELETE
TO authenticated
USING (uploaded_by_user_id = auth.uid()::text);

-- 4. Verify policies are created
SELECT 'Storage policies:' as info;
SELECT policyname, cmd, permissive
FROM pg_policies
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE 'captures_%'
ORDER BY policyname;

SELECT 'Table policies:' as info;
SELECT policyname, cmd, permissive
FROM pg_policies
WHERE schemaname = 'public' 
AND tablename = 'captures'
ORDER BY policyname;
