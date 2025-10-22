-- FINAL COMPREHENSIVE FIX FOR ALL STORAGE AND TABLE POLICIES
-- This script cleans up all duplicate/conflicting policies and creates working ones
-- Run this in Supabase SQL Editor with service role

-- ============================================
-- PART 1: CLEAN UP ALL EXISTING POLICIES
-- ============================================

DO $$
DECLARE
    pol RECORD;
BEGIN
    -- Drop ALL storage policies for avatars and captures
    FOR pol IN 
        SELECT DISTINCT policyname 
        FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects' 
        AND (policyname LIKE '%avatar%' OR policyname LIKE '%capture%')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
    END LOOP;
    
    -- Drop ALL table policies for captures
    FOR pol IN 
        SELECT DISTINCT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'captures'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.captures', pol.policyname);
    END LOOP;
END $$;

-- ============================================
-- PART 2: CREATE SIMPLE WORKING AVATAR POLICIES
-- ============================================

-- Allow everyone to read avatars
CREATE POLICY "avatar_read"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'avatars');

-- Allow authenticated users to upload avatars
-- The key should start with their UUID (case-insensitive)
CREATE POLICY "avatar_write"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars' 
    AND (
        -- Check if filename starts with user's UUID (case insensitive)
        LOWER(name) LIKE LOWER(auth.uid()::text) || '%'
        OR name LIKE auth.uid()::text || '%'
    )
);

-- Allow users to update their own avatars
CREATE POLICY "avatar_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars' 
    AND (
        LOWER(name) LIKE LOWER(auth.uid()::text) || '%'
        OR name LIKE auth.uid()::text || '%'
    )
)
WITH CHECK (
    bucket_id = 'avatars' 
    AND (
        LOWER(name) LIKE LOWER(auth.uid()::text) || '%'
        OR name LIKE auth.uid()::text || '%'
    )
);

-- Allow users to delete their own avatars
CREATE POLICY "avatar_remove"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars' 
    AND (
        LOWER(name) LIKE LOWER(auth.uid()::text) || '%'
        OR name LIKE auth.uid()::text || '%'
    )
);

-- ============================================
-- PART 3: CREATE SIMPLE WORKING CAPTURE POLICIES
-- ============================================

-- Allow everyone to read captures
CREATE POLICY "capture_read"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'captures');

-- Allow any authenticated user to upload captures
-- (Since we use user names as folders, we can't restrict by UUID)
CREATE POLICY "capture_write"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'captures');

-- Allow users to update any capture (simplified for now)
CREATE POLICY "capture_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'captures')
WITH CHECK (bucket_id = 'captures');

-- Allow users to delete captures in folders containing their UUID
CREATE POLICY "capture_remove"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'captures'
    AND (
        name LIKE '%' || auth.uid()::text || '%'
        OR name LIKE '%' || LOWER(auth.uid()::text) || '%'
    )
);

-- ============================================
-- PART 4: CREATE CAPTURES TABLE POLICIES
-- ============================================

-- Enable RLS on captures table
ALTER TABLE public.captures ENABLE ROW LEVEL SECURITY;

-- Check the data type of uploaded_by_user_id
DO $$
DECLARE
    col_type TEXT;
BEGIN
    SELECT data_type INTO col_type
    FROM information_schema.columns
    WHERE table_schema = 'public' 
    AND table_name = 'captures'
    AND column_name = 'uploaded_by_user_id';
    
    RAISE NOTICE 'uploaded_by_user_id column type: %', col_type;
END $$;

-- Create table policies - handle UUID column type properly

-- Allow users to insert their own captures
CREATE POLICY "captures_table_insert"
ON public.captures FOR INSERT
TO authenticated
WITH CHECK (uploaded_by_user_id = auth.uid());

-- Allow all authenticated users to read captures
CREATE POLICY "captures_table_read"
ON public.captures FOR SELECT
TO authenticated
USING (true);

-- Allow users to update their own captures
CREATE POLICY "captures_table_update"
ON public.captures FOR UPDATE
TO authenticated
USING (uploaded_by_user_id = auth.uid())
WITH CHECK (uploaded_by_user_id = auth.uid());

-- Allow users to delete their own captures
CREATE POLICY "captures_table_remove"
ON public.captures FOR DELETE
TO authenticated
USING (uploaded_by_user_id = auth.uid());

-- ============================================
-- PART 5: FIX PROFILES TABLE CONSTRAINTS
-- ============================================

-- Make age constraint more lenient
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_age_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_age_check 
    CHECK (age IS NULL OR age >= 0);

-- ============================================
-- PART 6: ENSURE BUCKETS ARE CONFIGURED
-- ============================================

-- Ensure avatars bucket exists with proper settings
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', false, 5242880, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/heic', 'image/heif', 'image/webp'])
ON CONFLICT (id) DO UPDATE
SET 
    public = false,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/heic', 'image/heif', 'image/webp'];

-- Ensure captures bucket exists with proper settings
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('captures', 'captures', false, 10485760, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/heic'])
ON CONFLICT (id) DO UPDATE
SET 
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/heic'];

-- ============================================
-- PART 7: VERIFY ALL POLICIES
-- ============================================

-- Check storage policies
SELECT 
    'STORAGE POLICIES:' as section,
    policyname,
    cmd,
    CASE 
        WHEN qual IS NULL THEN 'CHECK CONDITION'
        ELSE 'USING CONDITION'
    END as condition_type,
    COALESCE(qual, with_check) as condition
FROM pg_policies 
WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND (policyname LIKE '%avatar%' OR policyname LIKE '%capture%')
ORDER BY policyname;

-- Check table policies
SELECT 
    'TABLE POLICIES:' as section,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'captures'
ORDER BY policyname;

-- Check if there are any duplicate policies
SELECT 
    'DUPLICATE CHECK:' as section,
    policyname, 
    COUNT(*) as count
FROM pg_policies 
WHERE schemaname IN ('storage', 'public')
    AND (policyname LIKE '%avatar%' OR policyname LIKE '%capture%')
GROUP BY policyname
HAVING COUNT(*) > 1;

-- ============================================
-- PART 8: TEST QUERIES (Uncomment to test)
-- ============================================

/*
-- Test if a user can insert into captures table
-- Replace 'YOUR_USER_ID' with an actual UUID from auth.users
INSERT INTO public.captures (
    id,
    plot_id,
    taken_at,
    photo_key,
    uploaded_by_user_id,
    device_model
) VALUES (
    gen_random_uuid(),
    gen_random_uuid(),
    NOW(),
    'test_user/test_image.jpg',
    'YOUR_USER_ID',  -- Use actual UUID here
    'Test Device'
) RETURNING *;
*/

-- ============================================
-- PART 9: SUMMARY
-- ============================================

SELECT 
    'CLEANUP COMPLETE!' as status,
    'All duplicate policies removed and clean policies created' as message;

-- Count final policies
SELECT 
    'Total Storage Policies' as type,
    COUNT(*) as count
FROM pg_policies 
WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND (policyname LIKE '%avatar%' OR policyname LIKE '%capture%')
UNION ALL
SELECT 
    'Total Table Policies' as type,
    COUNT(*) as count
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'captures';
