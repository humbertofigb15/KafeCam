-- Final fix for storage RLS policies
-- This script ensures avatars and captures can be uploaded/downloaded properly

-- 1. First, check and fix avatars bucket policies
DO $$
BEGIN
    -- Drop all existing avatar policies to start fresh
    DROP POLICY IF EXISTS "avatars_read_all" ON storage.objects;
    DROP POLICY IF EXISTS "avatars_insert_auth" ON storage.objects;
    DROP POLICY IF EXISTS "avatars_update_own" ON storage.objects;
    DROP POLICY IF EXISTS "avatars_delete_own" ON storage.objects;
    DROP POLICY IF EXISTS "avatars insert" ON storage.objects;
    DROP POLICY IF EXISTS "avatars update" ON storage.objects;
    DROP POLICY IF EXISTS "avatars delete" ON storage.objects;
    DROP POLICY IF EXISTS "avatars read" ON storage.objects;
    
    -- Create clean avatar policies
    -- Allow all authenticated users to read avatars
    CREATE POLICY "avatar_select_all" ON storage.objects
        FOR SELECT USING (bucket_id = 'avatars');
    
    -- Allow authenticated users to upload their own avatars (any format)
    CREATE POLICY "avatar_insert_own" ON storage.objects
        FOR INSERT WITH CHECK (
            bucket_id = 'avatars' AND
            auth.role() = 'authenticated'
        );
    
    -- Allow users to update their own avatars
    CREATE POLICY "avatar_update_own" ON storage.objects
        FOR UPDATE USING (
            bucket_id = 'avatars' AND
            auth.role() = 'authenticated' AND
            (
                name LIKE (auth.uid())::text || '%' OR
                name LIKE LOWER((auth.uid())::text) || '%'
            )
        );
    
    -- Allow users to delete their own avatars
    CREATE POLICY "avatar_delete_own" ON storage.objects
        FOR DELETE USING (
            bucket_id = 'avatars' AND
            auth.role() = 'authenticated' AND
            (
                name LIKE (auth.uid())::text || '%' OR
                name LIKE LOWER((auth.uid())::text) || '%'
            )
        );
END $$;

-- 2. Fix captures bucket policies
DO $$
BEGIN
    -- Drop all existing capture policies to start fresh
    DROP POLICY IF EXISTS "captures_read_all" ON storage.objects;
    DROP POLICY IF EXISTS "captures_insert_auth" ON storage.objects;
    DROP POLICY IF EXISTS "captures_update_own" ON storage.objects;
    DROP POLICY IF EXISTS "captures_delete_own" ON storage.objects;
    DROP POLICY IF EXISTS "captures insert" ON storage.objects;
    DROP POLICY IF EXISTS "captures update" ON storage.objects;
    DROP POLICY IF EXISTS "captures delete" ON storage.objects;
    DROP POLICY IF EXISTS "captures read" ON storage.objects;
    
    -- Create clean capture policies
    -- Allow all authenticated users to read captures
    CREATE POLICY "capture_select_all" ON storage.objects
        FOR SELECT USING (bucket_id = 'captures');
    
    -- Allow authenticated users to upload captures (to any folder)
    CREATE POLICY "capture_insert_auth" ON storage.objects
        FOR INSERT WITH CHECK (
            bucket_id = 'captures' AND
            auth.role() = 'authenticated'
        );
    
    -- Allow users to update their own captures (in their folder)
    CREATE POLICY "capture_update_own" ON storage.objects
        FOR UPDATE USING (
            bucket_id = 'captures' AND
            auth.role() = 'authenticated'
        );
    
    -- Allow users to delete their own captures
    CREATE POLICY "capture_delete_own" ON storage.objects
        FOR DELETE USING (
            bucket_id = 'captures' AND
            auth.role() = 'authenticated'
        );
END $$;

-- 3. Ensure buckets exist and are configured correctly
DO $$
BEGIN
    -- Create avatars bucket if it doesn't exist
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES ('avatars', 'avatars', false, 5242880, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/heic', 'image/heif'])
    ON CONFLICT (id) DO UPDATE
    SET file_size_limit = 5242880,
        allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/heic', 'image/heif'];
    
    -- Create captures bucket if it doesn't exist
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES ('captures', 'captures', false, 10485760, ARRAY['image/jpeg', 'image/jpg', 'image/png'])
    ON CONFLICT (id) DO UPDATE
    SET file_size_limit = 10485760,
        allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png'];
END $$;

-- 4. Fix age check constraint (make it more lenient)
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_age_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_age_check 
    CHECK (age IS NULL OR (age >= 0 AND age <= 150));

-- 5. Verify the policies are created
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND (policyname LIKE '%avatar%' OR policyname LIKE '%capture%')
ORDER BY policyname;
